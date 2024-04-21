# Import python packages
import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd
import time

# Set app title and description
st.title(":balloon: Streamlit in Snowflake :snowflake:")
st.header("Demo for Snowflake Technical User Group")
st.subheader("Melbourne Chapter - 23 April 2024")
st.write(
    """This is a demo Streamlit in Snowflake (SiS) app
    to show one of many ways how user can leverage Snowflake Cortex
    (in this demo, the forecasting)."""
)
st.write(
    """The app shows the actual and forecasted revenue
    for a region selected in the filter panel, and allows
    user to update the target revenue up to the next
    12 months."""
)

# Get the current credentials
session = get_active_session()

# Create sidebar for filters
with st.sidebar:
    st.title("Filter Panel")
    # First filter is the Region
    distinct_region = session.sql(
        """
        SELECT DISTINCT REGION
        FROM DEMO_DATA
        ORDER BY REGION
        """
    ).collect()
    filter_region = st.selectbox(
        "Choose Region:",
        distinct_region,
    )
    # Second filter is the # of months to forecast
    filter_months = st.slider(
        "Month(s) to Forecast:",
        min_value = 1,
        max_value = 12,
        value = 4
    )
    st.write(f"Current user: {st.experimental_user['login_name']}")
    st.write(f"Streamlit version: {st.__version__}")

# Let's start with visualising all the region's revenue using a bar chart
df_region_revenue = session.sql(
    """
    SELECT *
    FROM REVENUE
        PIVOT (
            SUM(REVENUE)
            FOR REGION IN ('AU/NZ', 'US', 'UK')
        ) AS REVENUE
    ORDER BY MONTH
    """
).collect()
st.header("Revenue per Month by Region")
st.write("This bar chart shows the monthly revenue from each region.")
st.bar_chart(
    df_region_revenue,
    x="MONTH"
)

# Next, let's visualise the store location using map
df_store_loc = session.sql(
    f"""
    WITH REVENUE_PER_REGION AS (
        SELECT REGION, SUM(REVENUE) AS REVENUE
        FROM REVENUE
        WHERE REGION = '{filter_region}'
        GROUP BY REGION
    )
    SELECT s.STORE_ID
        , 'Store #' || s.STORE_ID::varchar AS STORE_NAME
        , s.LAT
        , s.LONG AS LON
        , s.PCT * r.REVENUE AS REVENUE
    FROM STORE_PCT s
    JOIN REVENUE_PER_REGION r
        ON s.REGION = r.REGION;
    """
).to_pandas()
st.header(f"Store Locations in {filter_region}")
st.write("This map shows the locations of each store.")
#st.map(df_store_loc, size="REVENUE")

#### USE PYDECK ####
import pydeck as pdk
# get average lat long
avg_lat = df_store_loc["LAT"].mean()
avg_lon = df_store_loc["LON"].mean()

# set initial view
view = pdk.data_utils.compute_view(
    df_store_loc[["LON", "LAT"]]
)
view.zoom = view.zoom - (1 if view.zoom > 5 else 0)

# get colour for each data point
color_lookup = pdk.data_utils.assign_random_colors(
    df_store_loc["STORE_NAME"]
)
df_store_loc["COLOUR"] = df_store_loc.apply(
    lambda row: color_lookup.get(row["STORE_NAME"]) + [140],
    axis = 1
)

# create the plot layer
plot_layer = pdk.Layer(
    "ScatterplotLayer",
    data=df_store_loc,
    get_position=["LON", "LAT"],
    get_fill_color="COLOUR",
    get_radius="REVENUE",
    radius_scale=3000/pow(view.zoom,2),
)

# create pydeck chart
st.pydeck_chart(
    pdk.Deck(
        map_style=None,
        layers = [plot_layer],
        initial_view_state = view,
    ),
)
####################

def get_revenue_data():
    """
    This function will get all the required revenue data
    and combine them into a single dataframe
    """
    # Get actual revenue data
    df_actual = session.sql(
        f"""
        SELECT a.MONTH
            , a.REVENUE AS ACTUAL
            , t.TARGET_REVENUE AS TARGET
        FROM REVENUE a
        LEFT JOIN DEMO_DATA t
            ON a.MONTH = t.MONTH
                AND a.REGION = t.REGION
        WHERE a.REGION = '{filter_region}'
        ORDER BY a.MONTH
        """
    ).to_pandas()
    # Get forecast revenue data
    df_forecast = session.sql(
        f"""
        CALL FORECAST_MODEL!FORECAST(
            FORECASTING_PERIODS => {filter_months}
        )
        """
    ).collect()

    # Get target revenue data
    df_target = session.sql(
        f"""
        SELECT CAST(MONTH AS TIMESTAMP_NTZ) AS MONTH
            , TARGET_REVENUE AS TARGET
        FROM "TARGET_REVENUE_{filter_region}" fr
        ORDER BY MONTH
        LIMIT {filter_months}
        """
    ).to_pandas()

    # Convert forecast to pandas dataframe and remove other series
    pdf_forecast = pd.DataFrame(df_forecast).rename(columns={"TS": "MONTH"})
    pdf_forecast.drop(
        pdf_forecast[pdf_forecast["SERIES"] != f'"{filter_region}"'].index,
        inplace=True
    )

    # Combine the data
    pdf_forecast_target = pd.merge(
        pdf_forecast.drop("SERIES", axis=1),
        df_target,
        on="MONTH",
        how="outer"
    )

    pdf_revenue = pd.concat(
        [
            df_actual,
            pdf_forecast_target
        ],
        ignore_index=True
    )

    return pdf_revenue

# Show the data as chart and table
st.header(f"Actual, Target and Forecasted Revenue per Month for {filter_region} Region")
st.write(
    f"""
    This line chart shows the actual vs target revenue for
    {filter_region}. It also shows what is the forecasted
    revenue for the next {filter_months} month(s).
    """)
df_revenue = get_revenue_data()
st.line_chart(
    df_revenue, 
    x="MONTH", 
    y=["ACTUAL", "TARGET", "FORECAST", "LOWER_BOUND", "UPPER_BOUND"]
)
st.subheader("Underlying Data")
st.write("This is the underlying data driving the chart above.")
st.dataframe(df_revenue)

# Allow user to adjust the target
st.header(f"Adjust Target for {filter_region} Region")
st.write(
    """
    Adjust the target revenue to a more realistic target
    based on the forecast above. Please don't be too hard
    on our sales team :sweat_smile:
    """
)
df_editable_target = session.table(
    f'"TARGET_REVENUE_{filter_region}"'
)
with st.form("Update Target Revenue"):
    df_edited_target = st.data_editor(
        df_editable_target,
        num_rows="dynamic"
    )
    save_button = st.form_submit_button("Save")

# Write back to table when save button is pressed
if save_button:
    try:
        with st.spinner("Saving target revenue..."):
            session.write_pandas(
                df_edited_target,
                f'"TARGET_REVENUE_{filter_region}"',
                database="USERSPACE_IGNATIUS_SOPUTRO",
                schema="X2",
                overwrite=True,
                quote_identifiers=False
            )
        st.success('Target revenue updated!', icon="✅")
        # pause for 2 seconds to give the success message time to show
        time.sleep(2)
        st.experimental_rerun()
    except Exception as e:
        st.warning(f"Error updating target revenue!\n{e}")

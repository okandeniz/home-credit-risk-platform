import requests
import streamlit as st

API_BASE_URL = "http://127.0.0.1:8000"

MANUAL_FIELD_GROUPS = {
    "Application & Financial Information": [
        "NAME_CONTRACT_TYPE",
        "AGE_YEARS",
        "DAYS_EMPLOYED",
        "AMT_INCOME_TOTAL",
        "AMT_CREDIT",
        "AMT_GOODS_PRICE",
        "AMT_ANNUITY",
        "ANNUITY_CREDIT_RATIO",
        "ANNUITY_INCOME_RATIO",
        "CREDIT_INCOME_RATIO",
    ],
    "Bureau Credit History": [
        "BUREAU_CREDIT_COUNT",
        "ACTIVE_BUREAU_CREDIT_COUNT",
        "TOTAL_BUREAU_CREDIT",
        "TOTAL_BUREAU_DEBT",
        "BUREAU_DEBT_CREDIT_RATIO",
        "TOTAL_BUREAU_OVERDUE",
        "DAYS_SINCE_MOST_RECENT_BUREAU_CREDIT",
    ],
    "Previous Applications": [
        "PREVIOUS_APPLICATION_COUNT",
        "PREVIOUS_REFUSED_COUNT",
        "PREVIOUS_APPROVAL_RATE",
        "MAX_PREVIOUS_CREDIT_AMOUNT",
        "AVG_PREVIOUS_APPLICATION_AMOUNT",
        "DAYS_SINCE_LAST_PREVIOUS_APPLICATION",
    ],
    "Payment & Credit Card History": [
        "LATE_PAYMENT_RATE",
        "UNDERPAYMENT_RATE",
        "TOTAL_ACTUAL_PAYMENT",
        "TOTAL_EXPECTED_PAYMENT",
        "PAYMENT_EVENT_COUNT",
        "AVG_LATE_PAYMENT_DAYS",
        "MAX_LATE_PAYMENT_DAYS",
        "AVG_CREDIT_UTILIZATION",
        "MAX_CREDIT_UTILIZATION",
        "CREDIT_CARD_MONTH_COUNT",
        "POS_MONTH_COUNT",
        "POS_CONTRACT_COUNT",
    ],
}

MANUAL_FIELDS = [
    field
    for fields in MANUAL_FIELD_GROUPS.values()
    for field in fields
]

## Adjusting the page title and width:
st.set_page_config(
    page_title="Home Credit Risk Platform",
    page_icon="📊",
    layout="wide",
)

st.title("Home Credit Risk Platform")
st.caption("Default Risk Prediction | LightGBM v1.0.0")

st.divider()

## Creating two separate forecast tabs:
tab_id, tab_manual = st.tabs([
    "Applicant ID Prediction",
    "Manual Prediction"
])

# Tab 1: Applicant ID Prediction

with tab_id:
    st.subheader("Prediction by Applicant ID")

    st.write(
        "Retrieve applicant features from SQL Server "
        "and predict payment difficulty."
    )

    ## Ensuring the user enters their application ID:
    applicant_id = st.number_input(
        "Applicant ID",
        min_value=1,
        value=316058,
        step=1
    )

    ## Starting the estimation process:
    if st.button(
        "Predict Risk",
        type="primary",
        key="predict_id",
    ):
        try:
            ## Sending an HTTP request to FastAPI:
            response = requests.get(
                f"{API_BASE_URL}/predict/{applicant_id}",
                timeout=30,
            )

            if response.status_code == 404:
                st.error("Applicant not found.")

            else:
                response.raise_for_status()
                ## Converting the API's JSON output into a Python dictionary
                result = response.json()

                st.success("Prediction completed.")

                col1, col2 = st.columns(2)

                with col1:
                    ## Indicating the risk probability and threshold value:
                    st.metric(
                        "Risk Probability",
                        f"{result['risk_probability']:.2%}",
                    )

                ## Notifying the user about the review status:
                with col2:
                    st.metric(
                        "Review Threshold",
                        f"{result['threshold']:.2%}",
                    )

                if result["risk_flag"] == 1:
                    st.warning(
                        "Review Recommended"
                    )
                else:
                    st.info(
                        "Below Review Threshold"
                    )

                st.caption(
                    f"Model Version: {result['model_version']}"
                )

        except requests.RequestException as exc:
            st.error(
                "Could not complete the API request. "
                "Check whether FastAPI is running."
            )
            st.caption(str(exc))

# Tab 2: Manual Prediction

with tab_manual:
    st.subheader("Manual Default Risk Prediction")

    st.write(
        "Enter applicant information manually or load "
        "a random TEST application."
    )

    if st.button(
        "🎲 Random Fill from TEST",
        key="random_fill",
    ):
        try:
            response = requests.get(
                f"{API_BASE_URL}/samples/random-test/form",
                timeout=30,
            )
            response.raise_for_status()

            sample = response.json()
            values = sample["values"]

            for field in MANUAL_FIELDS:
                st.session_state[f"manual_{field}"] = values[field]

            st.session_state["sample_applicant_id"] = (
                sample["applicant_id"]
            )

        except (requests.RequestException, KeyError) as exc:
            st.error(f"Could not load TEST sample: {exc}")

    if "sample_applicant_id" in st.session_state:
        st.caption(
            "Loaded TEST Applicant: "
            f"{st.session_state['sample_applicant_id']}"
        )

    for group_name, fields in MANUAL_FIELD_GROUPS.items():
        with st.expander(group_name, expanded=True):
            cols = st.columns(2)

            for i, field in enumerate(fields):
                with cols[i % 2]:
                    if field == "NAME_CONTRACT_TYPE":
                        st.selectbox(
                            "Contract Type",
                            options=[
                                "Cash loans",
                                "Revolving loans",
                            ],
                            index=None,
                            placeholder="Select contract type",
                            key=f"manual_{field}",
                        )

                    else:
                        st.number_input(
                            field.replace("_", " ").title(),
                            value=None,
                            format="%.4f",
                            key=f"manual_{field}",
                            help=field,
                        )

    st.caption(
        "Four Python-derived features are calculated "
        "automatically during prediction."
    )

    st.divider()

    if st.button(
        "Predict Risk",
        type="primary",
        key="predict_manual"
    ):

        # Collect values from all manual input fields
        manual_values = {
            field: st.session_state.get(f"manual_{field}")
            for field in MANUAL_FIELDS
        }

        missing_count = sum(
            value is None
            for value in manual_values.values()
        )

        if missing_count > 0:
            st.warning(
                f"{missing_count} input fields have missing values. "
                "Predictions may be less reliable."
            )

        try:
            response = requests.post(
                f"{API_BASE_URL}/predict/manual",
                json={"values": manual_values},
                timeout=30,
            )

            if response.status_code == 422:
                st.error("Invalid manual input.")
                st.json(response.json())

            else:
                response.raise_for_status()
                result = response.json()

                st.success("Manual prediction completed.")

                col1, col2 = st.columns(2)

                with col1:
                    st.metric(
                        "Risk Probability",
                        f"{result['risk_probability']:.2%}",
                    )

                with col2:
                    st.metric(
                        "Review Threshold",
                        f"{result['threshold']:.2%}",
                    )

                if result["risk_flag"] == 1:
                    st.warning("Review Recommended")
                else:
                    st.info("Below Review Threshold")

                st.caption(
                    f"Model Version: {result['model_version']}"
                )

        except requests.RequestException as exc:
            st.error(
                "Could not complete the prediction. "
                "Check the FastAPI connection."
            )
            st.caption(str(exc))
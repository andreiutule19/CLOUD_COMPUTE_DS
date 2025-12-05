import os
from typing import Any

import requests
import streamlit as st


BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8000")

st.set_page_config(page_title="Cloud Compute Demo", page_icon="☁️")
st.title("Cloud Compute Demo")
st.write(
    "Use this Streamlit UI to call the FastAPI backend service and fetch a personalised greeting."
)


def say_hello(name: str) -> dict[str, Any]:
    response = requests.post(f"{BACKEND_URL}/api/hello", json={"name": name}, timeout=10)
    response.raise_for_status()
    return response.json()



with st.form("hello_form", clear_on_submit=False):
    name = st.text_input("What is your name?", value="Azure Developer")
    submitted = st.form_submit_button("Say hello")


    if submitted:
        if not name.strip():
            st.error("Please enter a non-empty name.")
        else:
            try:
                data = say_hello(name.strip())
                st.success(data.get("message", "No message returned from backend."))
            except requests.HTTPError as exc:
                detail = exc.response.json().get("detail") if exc.response else str(exc)
                st.error(f"Backend responded with an error: {detail}")
            except requests.RequestException as exc:
                st.error(f"Unable to reach backend at {BACKEND_URL}: {exc}")


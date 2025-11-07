# Cloud Compute

This repository now hosts two Python services that can be developed locally and deployed to Azure App Service via the Azure Developer CLI (`azd`):

- `backend/` – FastAPI application that exposes a JSON API at `/api/hello`.
- `frontend/` – Streamlit application that calls the FastAPI API and renders an interactive UI.
- `infra/` – Bicep templates used by `azd` to provision shared Azure infrastructure (App Service Plan, two App Services, logging).

## Repository Setup

```text
backend/
  app/
    main.py
  requirements.txt
  startup.sh
frontend/
  app.py
  requirements.txt
infra/
  main.bicep
  main.parameters.json
azure.yaml
```

Both applications live in the same Git repository but in separate folders to allow independent development and deployment.

## Local Development

### Backend (FastAPI)

- Create & activate a virtual environment.
- Install dependencies: `pip install -r backend/requirements.txt`
- Run locally:
  - `cd backend`
  - `uvicorn app.main:app --reload`
- Visit `http://127.0.0.1:8000`

### Frontend (Streamlit)

- Create & activate a (separate) virtual environment or reuse the backend one.
- Install dependencies: `pip install -r frontend/requirements.txt`
- Ensure the backend is running and export `BACKEND_URL` if it is not using the default `http://localhost:8000`.
- Start Streamlit:
  - `cd frontend`
  - `streamlit run app.py`

The Streamlit UI will call the FastAPI endpoint at `/api/hello` and display the response.

## Azure Deployment with `azd`

1. Install the Azure Developer CLI: <https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd>
2. Authenticate: `azd auth login`
3. Initialize environment (once): `azd init`
4. Provision shared infrastructure and both services: `azd up`
   - This creates a resource group, App Service plan, and two App Services (one for FastAPI, one for Streamlit).
   - The Streamlit service receives `BACKEND_URL` via app settings pointing to the deployed FastAPI URL.
5. Deploy services separately if needed:
   - `azd deploy api`
   - `azd deploy frontend`

After deployment, retrieve endpoints with `azd env get-values` or from the Azure Portal.

## Notes

- The infrastructure uses a shared B1 App Service Plan. Update `infra/main.bicep` if you need a different SKU.
- Customize environment variables (for example, API authentication) by editing the `appSettings` section in `infra/main.bicep`.
- When running locally, the Streamlit app defaults to `http://localhost:8000` but respects the `BACKEND_URL` environment variable.

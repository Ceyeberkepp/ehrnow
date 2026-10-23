# EHRNow Windows setup wizard
In GitHub Actions select **Build EHRNow Windows Setup** and **Run workflow**, then download the **EHRNow-Setup-Windows-x64** artifact. Extract the ZIP and double-click the setup EXE.

The wizard copies the application, adds shortcuts, and launches a startup helper. On first start, it attempts to install Docker Desktop if missing, then prompts the user to complete Docker/WSL2 startup and relaunch EHRNow. A restart or elevation may be required. First startup downloads dependencies and builds the development services. This is not a zero-dependency/offline installer, and the EXE is not code-signed.

Development only; fake patient data only. Uninstalling EHRNow does not delete Docker data volumes. Not for production or clinical use.

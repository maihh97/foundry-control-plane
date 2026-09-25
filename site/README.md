# Zava control-plane showcase

This is a dependency-free static website for presenting the deployed Microsoft Foundry demo.

## Run locally

From the repository root:

```powershell
python -m http.server 8080 --directory site
```

Open <http://localhost:8080>.

## Publish

The repository's GitHub Pages workflow uploads this folder and deploys it to:

<https://maihh97.github.io/foundry-control-plane/>

The site contains no Azure credentials, API keys, tenant IDs, subscription IDs, or live data-plane calls. Deployment values are a reviewed, non-secret evidence snapshot.

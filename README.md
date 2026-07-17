# PubMed Central (PMC) Oncology Literature Ingestion Pipeline & Dashboard

An end-to-end asynchronous Python pipeline and interactive web dashboard designed to query, filter, download, parse, and persist Open Access (OA) oncology literature from PubMed Central (PMC).

The system targets specific publication types (Randomized Controlled Trials, Systematic Reviews, Meta-Analyses, Practice Guidelines) in the oncology domain and builds a structured local corpus of full-text papers.

---

## Features

### 🚀 Asynchronous Data Ingestion Pipeline
- **Stage 1: Domain-Specific Search:** Uses NCBI E-utilities (`esearch`) to identify papers within the past 5 years matching precise oncology queries and MeSH terms.
- **Stage 1.5: Species Metadata Filtering:** Resolves PubMed MeSH indices to exclude animal-only studies and focus strictly on human research.
- **Stage 2: Identifier Conversion:** Translates PubMed IDs (PMIDs) to PubMed Central IDs (PMCIDs) and DOIs in bulk batches.
- **Stage 3: Open Access Verification:** Filters PMCIDs against the PMC OAI-PMH service to verify OA licensing and retrieve full-text XML download URLs.
- **Stage 4: Asynchronous Downloader:** Downloads full-text XMLs using `aiohttp` and `asyncio` with:
  - Robust rate-limiting (token bucket algorithm).
  - Exponential backoff retry logic.
  - Checkpoint persistence to safely resume interrupted runs.
- **Deduplication & Extraction:** Parses PMC XML articles (using `lxml`), extracts structured metadata (Title, Authors, Journal, Dates, Abstract, Sections, Figures, Tables, Citations), and saves them as:
  - Structured **JSON files**
  - Raw **XML files**
  - Rows in a **SQLite database**

### 📊 Web-Based Management Dashboard
- **Real-Time Pipeline Tracking:** Monitor current execution logs, active stages, throughput, and progress.
- **Footprint Estimator:** Run dry-run estimations to calculate the expected storage footprint (database size, XML/JSON storage requirements) before initiating massive downloads.
- **Corpus Analytics:** Visual statistics on downloaded article types, publication dates, and database volume.
- **Control Interface:** Start, pause, or kill pipeline execution dynamically from the web page.

---

## Project Structure

```
pmc-pipeline/
├── dashboard/                   # Web dashboard codebase
│   ├── app.py                   # Aiohttp web server & subprocess supervisor
│   └── static/                  # HTML, CSS, and JS files for the UI
│       ├── index.html
│       ├── style.css
│       └── app.js
├── data/                        # Local data directory (Git ignored)
│   ├── checkpoints/             # Resume state json files
│   ├── json/                    # Parsed structured JSON articles
│   ├── xml/                     # Raw full-text XML articles
│   ├── logs/                    # Execution logs
│   └── metadata/                # SQLite database (papers.db)
├── pipeline/                    # Pipeline modular package
│   ├── config.py                # Config parser with .env & env var fallback
│   ├── database.py              # SQLite schema & database handlers
│   ├── dedup.py                 # File & database deduplication logic
│   ├── downloader.py            # XML fetcher & XML parsing engine
│   ├── id_converter.py          # PMID to PMCID translator
│   ├── oa_filter.py             # Open Access license validation
│   ├── search.py                # PubMed E-utilities searcher
│   ├── species_filter.py        # Species MeSH verification
│   └── utils.py                 # Checkpoints, rate limiting, and trackers
├── .env.example                 # Template for setting up environment variables
├── .gitignore                   # Standard gitignore configurations
├── config.yaml.example          # Template for project-wide configuration parameters
├── requirements.txt             # Python dependency list
├── run_pipeline.py              # Main pipeline execution entry point
└── update_papers.py             # Utility to manually query and update the database
```

---

## Requirements & Setup

### 1. Prerequisites
- Python 3.9 or higher installed.
- Git.

### 2. Installation
Clone the repository:
```bash
git clone https://github.com/Cosmicgod5151/data_ingestion_pipeline.git
cd data_ingestion_pipeline
```

Set up a virtual environment and install the required dependencies:
```bash
# Create a virtual environment
python -m venv venv

# Activate the virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Configuration
The application requires a configuration file and optionally reads credentials from environment variables to prevent rate limiting (NCBI limits requests without keys).

1. Copy the example configuration:
   ```bash
   cp config.yaml.example config.yaml
   ```
2. Configure environment variables. You can set these directly in your shell or create a local `.env` file in the root folder:
   ```bash
   # Create a local .env file
   echo NCBI_API_KEY=your_ncbi_api_key_here >> .env
   echo NCBI_EMAIL=your_email_here >> .env
   ```
   *Note: Creating a `.env` file is highly recommended to protect your keys. Both `config.yaml` and `.env` are listed in `.gitignore` and will not be committed.*

---

## Usage

### Running the Ingestion Pipeline
You can trigger the pipeline from the command line inside your activated virtual environment:

```bash
# Run the pipeline from scratch
python run_pipeline.py

# Resume an interrupted run (loads the last stage checkpoint)
python run_pipeline.py --resume

# Run a dry-run (searches and checks counts but doesn't download XML/JSON)
python run_pipeline.py --dry-run

# Limit the maximum number of papers to download
python run_pipeline.py --max-papers 500

# Specify a custom configuration file path
python run_pipeline.py --config my_config.yaml
```

### Launching the Web Dashboard
To view corpus analytics, calculate storage estimates, or run/monitor the pipeline from your browser, launch the dashboard:

```bash
python dashboard/app.py
```
After launching, open your browser and navigate to:
```
http://localhost:8080
```

---

## Security & Best Practices
To maintain clean and secure repository structures, the following guidelines are configured:
- **Zero Credentials Committed:** API keys, emails, and tokens are decoupled from the static yaml files and loaded via `.env` or system environment variables.
- **Corpus Segregation:** Raw downloads (`data/xml/`, `data/json/`), run checkpoints, databases, and logs are saved inside the gitignored `data/` folder.
- **Environment Isolation:** The `venv` directory is excluded from version control.

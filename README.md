# Retrieval-Augmented Generation (RAG) on SQL Server 2025 in Linux

SQL Server 2025 introduces native vector search, allowing RAG workloads to run entirely inside SQL Server.

This marks one of the largest architectural evolutions in the history of the SQL Server engine by introducing native vector data types, vector search, and DiskANN‑powered vector indexing directly inside the database engine. This transformation enables developers to run complete Retrieval‑Augmented Generation (RAG) workloads entirely inside SQL Server, without needing external vector databases, search engines, or complex distributed architectures.
With these capabilities, SQL Server becomes an AI‑ready, ground‑to‑cloud database that can store embeddings, perform semantic search, orchestrate retrieval, and integrate with AI models from Azure OpenAI, OpenAI, or locally hosted models such as Ollama.

<img width="1624" height="828" alt="image" src="https://github.com/user-attachments/assets/0d0cf62d-7f8a-45d6-ad2a-4f90930561a5" />


SQL Server 2025 collapses all the various components of traditionally build a RAG system into one engine, eliminating cross‑system latency, complexity, and security concerns. With native vector operations, SQL Server allows:

- Storing high‑dimensional embeddings using the built‑in VECTOR(n) type
- Running semantic similarity search with VECTOR_DISTANCE and VECTOR_SEARCH
- Accelerating searches at scale using DiskANN vector indexes
- Generating embeddings via external models through sp_invoke_external_rest_endpoint
- Building RAG pipelines in pure T‑SQL

This repository contains complete SQL scripts to ingest unstructured text, generate embeddings, store them in native vector columns, perform vector similarity search, and call Azure OpenAI GPT-5 for grounded RAG answers.
```
/
├── README.md
└── sql/
    ├── 00_enable_features.sql
    ├── 01_create_staging_table.sql
    ├── 02_bulk_insert_csv.sql
    ├── 03_create_rag_table.sql
    ├── 04_load_into_rag_table.sql
    ├── 05_generate_embeddings.sql
    ├── 06_create_vector_index.sql      (optional but recommended)
    ├── 07_create_rag_procedure.sql
    └── 08_test_rag_query.sql


```
## RAG Demo Using Netflix Reviews (Kaggle Dataset)

## 1. Using Open AI models

This RAG demonstration uses the Netflix Reviews dataset from Kaggle, a real-world collection of user-generated app reviews from the Google Play Store. Each record contains a review ID, reviewer name, written feedback, rating score, application version, and timestamp.

The dataset was selected because it represents unstructured text at scale, containing thousands of natural-language user comments that vary in tone, sentiment, and detail. This makes it ideal for showcasing how SQL Server 2025’s native vector search capabilities can transform raw text into a searchable semantic index.

In this scenario, the reviews are ingested into SQL Server, embedded using Azure OpenAI’s text-embedding-3-small model, and stored as high-dimensional vectors. SQL Server then performs semantic retrieval using vector similarity, enabling the system to locate the most relevant reviews for a given question even when the question does not contain exact keywords from the original text.

The RAG stored procedure combines the retrieved context with a GPT-5 prompt, producing grounded, explainable answers using only the information found in the reviews. This simulates real product-support, feedback-analysis, and Q&A use cases commonly found in enterprise environments.

This end-to-end setup demonstrates how SQL Server 2025 and Azure OpenAI can be used together to build intelligent, data-driven Q&A systems directly on top of operational data.

<img width="708" height="341" alt="image" src="https://github.com/user-attachments/assets/93275766-686e-4486-9e71-3669c1b3d671" />

## 2. Using Ollama models

> 🚧 Work in progress  
> Instructions for configuring and using Ollama models will be added in a future update.



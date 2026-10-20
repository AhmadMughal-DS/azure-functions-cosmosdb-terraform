# Architecture Diagram — Azure Functions + Cosmos DB

## Lucid diagram

- **View:** https://lucid.app/lucidchart/da1c47fb-1ae2-4f69-a1f7-7239488676bc/view
- **Edit:** https://lucid.app/lucidchart/da1c47fb-1ae2-4f69-a1f7-7239488676bc/edit

## Lucid prompt (reusable)

```
Create an Azure architecture diagram titled "Azure Functions + Cosmos DB".
A Client sends an HTTPS trigger to an Azure Functions app (consumption plan); the
function reads and writes a Cosmos DB (SQL API) account, and uses a Storage Account
for its runtime. Label the arrows. Clean, professional Azure colors.
```

## Mermaid source

```mermaid
flowchart LR
    Client([Client])
    Func[Azure Functions - Consumption]
    Cosmos[(Cosmos DB - SQL API)]
    Storage[(Storage Account)]
    Client -->|HTTPS trigger| Func
    Func -->|read/write| Cosmos
    Func -.runtime.-> Storage
```

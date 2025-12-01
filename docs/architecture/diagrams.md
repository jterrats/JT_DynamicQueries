---
layout: default
title: Architecture Diagrams
---

# Architecture Diagrams

## 📊 System Overview

```mermaid
graph TB
    subgraph "User Interface Layer"
        QV[jtQueryViewer<br/>Main Component]
        CB[jtSearchableCombobox<br/>Config Selector]
        PI[jtParameterInputs<br/>Dynamic Params]
        EB[jtExecuteButton<br/>Smart Button]
        QR[jtQueryResults<br/>Results Display]
        CM[jtConfigModal<br/>Config Creator]
        UM[jtUsageModal<br/>Usage Finder]
        RA[jtRunAsSection<br/>User Context]
        CA[jtCacheModal<br/>Cache Manager]
    end

    subgraph "Controller Layer"
        QVC[JT_QueryViewerController<br/>Query Execution]
        MC[JT_MetadataCreator<br/>Config Management]
        UF[JT_UsageFinder<br/>Usage Search]
        PS[JT_ProductionSettingsController<br/>Settings]
        RTE[JT_RunAsTestExecutor<br/>Test Context]
    end

    subgraph "Core Engine"
        DS[JT_DataSelector<br/>Singleton Pattern]
        subgraph "Features"
            CE[Config Caching]
            QE[Query Execution]
            SE[Security Enforcement]
            PC[Platform Cache]
        end
    end

    subgraph "Salesforce Platform"
        MD[Custom Metadata]
        TA[Tooling API]
        SO[Standard Objects]
        FW[Flows]
    end

    QV --> CB
    QV --> PI
    QV --> EB
    QV --> QR
    QV --> CM
    QV --> UM
    QV --> RA
    QV --> CA

    CB --> QVC
    EB --> QVC
    CM --> MC
    UM --> UF
    RA --> RTE
    CA --> QVC

    QVC --> DS
    MC --> MD
    UF --> TA
    UF --> SO
    UF --> FW
    PS --> MD
    RTE --> DS

    DS --> CE
    DS --> QE
    DS --> SE
    DS --> PC

    DS --> MD
    DS --> SO

    style QV fill:#667eea,stroke:#333,stroke-width:4px,color:#fff
    style DS fill:#764ba2,stroke:#333,stroke-width:4px,color:#fff
    style QVC fill:#48bb78,stroke:#333,stroke-width:2px
    style MC fill:#48bb78,stroke:#333,stroke-width:2px
    style UF fill:#48bb78,stroke:#333,stroke-width:2px
```

---

## 🔄 Query Execution Flow

```mermaid
sequenceDiagram
    actor User
    participant QV as jtQueryViewer
    participant CB as jtSearchableCombobox
    participant EB as jtExecuteButton
    participant QVC as QueryViewerController
    participant DS as JT_DataSelector
    participant SF as Salesforce DB
    participant QR as jtQueryResults

    User->>CB: Select Configuration
    CB->>QVC: getConfigurations()
    QVC->>DS: getInstance()
    DS->>DS: Check Cache
    DS-->>QVC: Configurations
    QVC-->>CB: Return List
    CB-->>QV: Config Selected

    QV->>EB: Enable Execute
    User->>EB: Click Execute
    EB->>QVC: executeQuery(config, params)
    QVC->>DS: executeQuery(query, bindings)
    DS->>DS: Apply Security (USER_MODE)
    DS->>SF: Database.query()
    SF-->>DS: Results
    DS-->>QVC: Secure Results
    QVC-->>QR: Display Results
    QR-->>User: Show Data

    Note over DS,SF: WITH USER_MODE enforcement<br/>Respects FLS & Sharing
```

---

## 🏗️ Component Architecture

```mermaid
graph LR
    subgraph "jtQueryViewer (Orchestrator)"
        direction TB
        S[State Management]
        E[Event Handling]
        L[Labels/i18n]
    end

    subgraph "Smart Components"
        direction TB
        SC1[jtSearchableCombobox<br/>🔍 Search & Filter]
        SC2[jtExecuteButton<br/>▶️ Validation]
        SC3[jtParameterInputs<br/>📝 Dynamic Forms]
        SC4[jtQueryResults<br/>📊 Multi-View]
    end

    subgraph "Modal Components"
        direction TB
        M1[jtConfigModal<br/>➕ Create/Edit]
        M2[jtUsageModal<br/>🔍 Find Usage]
        M3[jtCacheModal<br/>🔄 Cache Mgmt]
    end

    subgraph "Feature Components"
        direction TB
        F1[jtRunAsSection<br/>👤 User Context]
        F2[jtSupport<br/>💬 Help]
    end

    S --> SC1
    S --> SC2
    S --> SC3
    S --> SC4
    E --> M1
    E --> M2
    E --> M3
    E --> F1
    L --> SC1
    L --> SC2
    L --> M1

    style S fill:#667eea,color:#fff
    style E fill:#667eea,color:#fff
    style L fill:#667eea,color:#fff
    style SC1 fill:#48bb78,color:#fff
    style SC2 fill:#48bb78,color:#fff
    style SC3 fill:#48bb78,color:#fff
    style SC4 fill:#48bb78,color:#fff
```

---

## 🛡️ Security Architecture

```mermaid
graph TD
    U[User Request] --> V{Validation}
    V -->|Valid| SM[Security Mode]
    V -->|Invalid| E1[Error: Invalid Input]

    SM --> UM{User Mode?}
    UM -->|Yes| RC[Run As Context]
    UM -->|No| DC[Direct Context]

    RC --> P1[Check Permissions]
    P1 -->|Allowed| Q[Execute Query]
    P1 -->|Denied| E2[Error: No Permission]

    DC --> Q

    Q --> SE[Security Enforcement]
    SE --> FLS[Field-Level Security]
    SE --> SR[Sharing Rules]
    SE --> OBJ[Object Permissions]

    FLS --> DB[Database.query<br/>WITH USER_MODE]
    SR --> DB
    OBJ --> DB

    DB --> F{Filter Results}
    F --> R[Secure Results]

    R --> A[Audit Log]
    A --> U2[Return to User]

    style V fill:#fbbf24,stroke:#333,stroke-width:2px
    style SE fill:#ef4444,stroke:#333,stroke-width:3px,color:#fff
    style DB fill:#10b981,stroke:#333,stroke-width:2px
    style R fill:#3b82f6,stroke:#333,stroke-width:2px
```

---

## 🔍 Usage Finder (Microservices Pattern)

```mermaid
graph TB
    U[User] --> UF[Usage Finder]
    UF --> O[Orchestrator<br/>findAllUsagesResilient]

    O -->|Parallel| S1[Service 1<br/>findInApexClassesService]
    O -->|Parallel| S2[Service 2<br/>findInFlowsService]

    S1 -->|Success| TA1[Tooling API<br/>ApexClass Query]
    S1 -->|Failure| E1[Error Handler 1]

    S2 -->|Success| TA2[Tooling API<br/>Flow Query]
    S2 -->|Failure| E2[Error Handler 2]

    TA1 --> R1[Results 1]
    TA2 --> R2[Results 2]
    E1 --> R1
    E2 --> R2

    R1 --> AGG[Aggregator]
    R2 --> AGG

    AGG --> RES[Combined Results<br/>+ Service Status]
    RES --> UM[jtUsageModal]
    UM --> U

    style O fill:#667eea,stroke:#333,stroke-width:3px,color:#fff
    style S1 fill:#48bb78,stroke:#333,stroke-width:2px
    style S2 fill:#48bb78,stroke:#333,stroke-width:2px
    style E1 fill:#ef4444,stroke:#333,stroke-width:2px,color:#fff
    style E2 fill:#ef4444,stroke:#333,stroke-width:2px,color:#fff
    style AGG fill:#764ba2,stroke:#333,stroke-width:3px,color:#fff
```

---

## 💾 Cache Strategy

```mermaid
graph LR
    subgraph "Cache Layers"
        direction TB
        L1[Wire Service Cache<br/>@wire getConfigurations]
        L2[Component State<br/>Query Results]
        L3[Platform Cache<br/>Shared Configs]
        L4[User Preferences<br/>Recent Selections]
    end

    subgraph "Cache Operations"
        direction TB
        R[Read]
        W[Write]
        I[Invalidate]
    end

    subgraph "Cache Modal"
        direction TB
        CB1[Clear Configurations]
        CB2[Clear Results]
        CB3[Clear Users]
        CB4[Clear Recent]
    end

    R --> L1
    R --> L2
    R --> L3
    R --> L4

    W --> L2
    W --> L4

    CB1 --> I
    CB2 --> I
    CB3 --> I
    CB4 --> I

    I --> L1
    I --> L2
    I --> L3
    I --> L4

    style L1 fill:#3b82f6,color:#fff
    style L2 fill:#3b82f6,color:#fff
    style L3 fill:#3b82f6,color:#fff
    style L4 fill:#3b82f6,color:#fff
    style I fill:#ef4444,color:#fff
```

---

## 🌐 i18n Architecture

```mermaid
graph TD
    U[User Browser] --> D[Detect Locale]
    D --> L[labels.js]

    L --> EN[English<br/>Default]
    L --> ES[Spanish<br/>Español]
    L --> FR[French<br/>Français]
    L --> DE[German<br/>Deutsch]
    L --> IT[Italian<br/>Italiano]
    L --> JA[Japanese<br/>日本語]

    EN --> GL[getLabels Function]
    ES --> GL
    FR --> GL
    DE --> GL
    IT --> GL
    JA --> GL

    GL --> C[All Components]
    C --> UI[User Interface]

    style L fill:#667eea,stroke:#333,stroke-width:3px,color:#fff
    style GL fill:#48bb78,stroke:#333,stroke-width:2px,color:#fff
    style UI fill:#764ba2,stroke:#333,stroke-width:2px,color:#fff
```

---

## 📱 Responsive Design Strategy

```mermaid
graph TB
    V[Viewport Detection] --> D{Device Type?}

    D -->|Desktop| DV[Desktop View<br/>≥1024px]
    D -->|Tablet| TV[Tablet View<br/>768-1023px]
    D -->|Mobile| MV[Mobile View<br/><768px]

    DV --> DT[Data Table]
    DT --> P[Pagination]
    DT --> F[Full Features]

    TV --> DT2[Compact Table]
    DT2 --> P2[Pagination]
    DT2 --> F2[Most Features]

    MV --> C[Card Layout]
    C --> E[Expandable]
    C --> S[Swipe Actions]
    C --> F3[Core Features]

    F --> R[Results Display]
    F2 --> R
    F3 --> R

    style DV fill:#3b82f6,color:#fff
    style TV fill:#10b981,color:#fff
    style MV fill:#f59e0b,color:#fff
    style R fill:#667eea,color:#fff
```

---

## 🧪 Testing Strategy

```mermaid
graph TB
    subgraph "Test Pyramid"
        direction TB
        E2E[E2E Tests<br/>28 Playwright Tests<br/>🎭]
        INT[Integration Tests<br/>Apex Test Classes<br/>⚙️]
        UNIT[Unit Tests<br/>Component Logic<br/>🔬]
    end

    subgraph "Test Coverage"
        direction TB
        A11Y[Accessibility Tests<br/>Axe-core + WCAG 2.1 AA<br/>♿]
        I18N[i18n Validation<br/>6 Languages<br/>🌐]
        RESP[Responsive Tests<br/>Mobile + Desktop<br/>📱]
    end

    subgraph "Quality Gates"
        direction TB
        COV[75%+ Coverage<br/>✅]
        LINT[ESLint + PMD<br/>✅]
        SEC[Security Scan<br/>✅]
    end

    UNIT --> INT
    INT --> E2E
    E2E --> A11Y
    E2E --> I18N
    E2E --> RESP

    A11Y --> COV
    I18N --> LINT
    RESP --> SEC

    COV --> PASS[✅ Production Ready]
    LINT --> PASS
    SEC --> PASS

    style E2E fill:#667eea,stroke:#333,stroke-width:3px,color:#fff
    style A11Y fill:#48bb78,stroke:#333,stroke-width:2px,color:#fff
    style PASS fill:#10b981,stroke:#333,stroke-width:4px,color:#fff
```

---

## 🚀 Deployment Pipeline

```mermaid
graph LR
    DEV[Development<br/>🛠️] --> TEST[Testing<br/>🧪]
    TEST --> QA[QA/Staging<br/>✅]
    QA --> PROD[Production<br/>🚀]

    DEV --> SCAN1[Code Scan<br/>PMD+ESLint]
    TEST --> E2E1[E2E Tests<br/>28 Tests]
    QA --> MAN[Manual QA<br/>Smoke Tests]

    SCAN1 --> |Pass| TEST
    E2E1 --> |Pass| QA
    MAN --> |Approve| PROD

    PROD --> MON[Monitoring<br/>📊]
    MON --> AUDIT[Audit Logs<br/>📝]

    style DEV fill:#3b82f6,color:#fff
    style TEST fill:#10b981,color:#fff
    style QA fill:#f59e0b,color:#fff
    style PROD fill:#ef4444,color:#fff,stroke:#333,stroke-width:4px
```

---

## 📊 Data Flow

```mermaid
flowchart TD
    Start([User Action]) --> Select{Select Config?}
    Select -->|Yes| Cache{In Cache?}
    Cache -->|Yes| Load[Load from Cache]
    Cache -->|No| Fetch[Fetch from Metadata]
    Fetch --> Store[Store in Cache]
    Store --> Load

    Load --> Params{Has Params?}
    Params -->|Yes| Input[User Input]
    Params -->|No| Execute

    Input --> Validate{Valid?}
    Validate -->|No| Error1[Show Error]
    Validate -->|Yes| Execute[Execute Query]

    Execute --> Security[Apply Security]
    Security --> Query[Database Query<br/>WITH USER_MODE]
    Query --> Results{Has Results?}

    Results -->|Yes| Display[Display Results]
    Results -->|No| Empty[Show Empty State]

    Display --> Format{View Mode?}
    Format -->|Table| Table[Table View]
    Format -->|JSON| JSON[JSON View]
    Format -->|CSV| CSV[CSV Export]

    Table --> End([Done])
    JSON --> End
    CSV --> End
    Empty --> End
    Error1 --> End

    style Start fill:#667eea,stroke:#333,stroke-width:2px,color:#fff
    style Execute fill:#48bb78,stroke:#333,stroke-width:2px,color:#fff
    style Security fill:#ef4444,stroke:#333,stroke-width:2px,color:#fff
    style End fill:#764ba2,stroke:#333,stroke-width:2px,color:#fff
```

---

## 🎨 Component Hierarchy

```mermaid
graph TD
    App[Lightning App<br/>JT Dynamic Queries]

    App --> Tab1[Query Viewer Tab]
    App --> Tab2[Documentation Tab]
    App --> Tab3[Support Tab]

    Tab1 --> QV[jtQueryViewer<br/>🎯 Main Component]

    QV --> Header[Header Section]
    QV --> Body[Body Section]
    QV --> Modals[Modals Section]

    Header --> CB[jtSearchableCombobox]
    Header --> CM[jtCacheModal]

    Body --> PI[jtParameterInputs]
    Body --> RA[jtRunAsSection]
    Body --> EB[jtExecuteButton]
    Body --> QR[jtQueryResults]

    Modals --> M1[jtConfigModal]
    Modals --> M2[jtUsageModal]

    Tab2 --> PD[jtProjectDocs]
    Tab3 --> SP[jtSupport]

    style App fill:#667eea,stroke:#333,stroke-width:4px,color:#fff
    style QV fill:#764ba2,stroke:#333,stroke-width:3px,color:#fff
    style QR fill:#48bb78,stroke:#333,stroke-width:2px,color:#fff
```

---

## 💡 Key Design Patterns

### Singleton Pattern

```mermaid
classDiagram
    class JT_DataSelector {
        -static JT_DataSelector instance
        -Map~String,Configuration~ configCache
        +static getInstance() JT_DataSelector
        +executeQuery(query, bindings) List~SObject~
        -validateQuery(query) Boolean
        -applySecurityMode(query) String
    }
    note for JT_DataSelector "Singleton ensures single instance<br/>Manages config cache<br/>Enforces security"
```

### Observer Pattern

```mermaid
classDiagram
    class jtQueryViewer {
        +handleConfigSelect()
        +handleExecute()
        +handleClearCache()
    }
    class jtSearchableCombobox {
        +dispatchEvent(select)
    }
    class jtExecuteButton {
        +dispatchEvent(execute)
    }
    class jtCacheModal {
        +dispatchEvent(clearcache)
    }

    jtSearchableCombobox --> jtQueryViewer: configselect
    jtExecuteButton --> jtQueryViewer: execute
    jtCacheModal --> jtQueryViewer: clearcache
```

---

## 📈 Performance Metrics

```mermaid
graph LR
    subgraph "Load Times"
        L1[Initial Load<br/>< 2s]
        L2[Config Load<br/>< 500ms]
        L3[Query Execute<br/>< 3s]
    end

    subgraph "Caching"
        C1[Cache Hit Rate<br/>> 80%]
        C2[Cache Size<br/>< 5MB]
    end

    subgraph "User Experience"
        U1[First Paint<br/>< 1s]
        U2[Interactive<br/>< 2.5s]
        U3[Smooth 60fps<br/>✅]
    end

    L1 --> M[Meets Target]
    L2 --> M
    L3 --> M
    C1 --> M
    C2 --> M
    U1 --> M
    U2 --> M
    U3 --> M

    M --> PASS[🎯 Performance<br/>Optimized]

    style L1 fill:#10b981,color:#fff
    style L2 fill:#10b981,color:#fff
    style L3 fill:#10b981,color:#fff
    style PASS fill:#667eea,stroke:#333,stroke-width:4px,color:#fff
```

---

> **Note:** All diagrams are interactive on GitHub Pages. View source for Mermaid syntax.

**Last Updated:** {{ site.time | date: '%B %d, %Y' }}

import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter, Link, NavLink, Route, Routes } from 'react-router-dom';
import './styles.css';

const capabilities = [
  {
    title: 'Reusable SOQL Workflows',
    body: 'Custom Metadata stores named query configurations so teams can reuse validated data access patterns.',
  },
  {
    title: 'Permission-Aware Testing',
    body: 'Run As flows help validate sharing, FLS, CRUD, and persona-based access without switching org users.',
  },
  {
    title: 'Multi-View Results',
    body: 'Developers can inspect records as tables, JSON, or CSV-ready output for debugging and handoff evidence.',
  },
  {
    title: 'Enterprise Data Volumes',
    body: 'Cursor-style navigation and cache boundaries keep large record sets usable inside Salesforce limits.',
  },
];

const layers = [
  {
    name: 'Lightning Web Components',
    details: 'jtQueryViewer, setup wizard, persona manager, parameter inputs, support and documentation surfaces.',
  },
  {
    name: 'Apex Controllers',
    details: 'Entry points validate inputs, enforce security posture, and delegate query execution and setup actions.',
  },
  {
    name: 'Domain Services',
    details: 'Selectors, audit logging, execution state, binding utilities, and metadata creation own behavior.',
  },
  {
    name: 'Salesforce Platform',
    details: 'Custom Metadata, custom settings, platform cache, org data, Tooling API, and audit records.',
  },
];

const flows = [
  'Select a named query configuration',
  'Resolve bindings and security mode',
  'Execute SOQL through Apex services',
  'Render records in table, JSON, tree, or CSV views',
  'Capture audit and troubleshooting evidence',
];

const demos = [
  {
    title: 'Query Execution',
    body: 'Run configured SOQL and inspect governed results from the Lightning UI.',
    src: '/assets/gifs/01-query-execution.gif',
  },
  {
    title: 'Multiple Views',
    body: 'Switch between table, JSON, CSV-ready, and structured views without rerunning the query.',
    src: '/assets/gifs/02-multiple-views.gif',
  },
  {
    title: 'Tree View',
    body: 'Traverse nested records and related data in an inspection-friendly layout.',
    src: '/assets/gifs/03-tree-view.gif',
  },
  {
    title: 'Large Dataset Navigation',
    body: 'Move through larger datasets with cursor-style navigation and bounded rendering.',
    src: '/assets/gifs/04-large-dataset.gif',
  },
  {
    title: 'Create Configuration',
    body: 'Create reusable named query configurations for admins and developers.',
    src: '/assets/gifs/05-create-config.gif',
  },
  {
    title: 'Run As User',
    body: 'Validate CRUD, FLS, sharing, and row visibility from a specific user context.',
    src: '/assets/gifs/06-run-as-user.gif',
  },
  {
    title: 'Run As Persona',
    body: 'Test access behavior through reusable personas instead of one-off manual user switching.',
    src: '/assets/gifs/07-run-as-persona.gif',
  },
  {
    title: 'Manage Personas',
    body: 'Maintain persona definitions that make permission validation repeatable.',
    src: '/assets/gifs/08-manage-personas.gif',
  },
];

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <div className="app-shell">
      <header className="topbar">
        <NavLink className="brand" to="/">
          JT Dynamic Queries
        </NavLink>
        <nav className="nav-links" aria-label="Primary navigation">
          <NavLink to="/">Home</NavLink>
          <NavLink to="/architecture">Architecture</NavLink>
          <a href="/#demos">Demos</a>
          <a href="https://github.com/jterrats/JT_DynamicQueries/tree/main/docs">Docs</a>
          <a href="https://jterrats.dev">Main site</a>
          <a href="https://github.com/jterrats/JT_DynamicQueries">GitHub</a>
        </nav>
      </header>
      {children}
    </div>
  );
}

function Home() {
  return (
    <Shell>
      <main>
        <section className="hero">
          <p className="eyebrow">Salesforce LWC Framework</p>
          <h1>Reusable dynamic SOQL workflows for Salesforce teams.</h1>
          <p className="lead">
            JT Dynamic Queries gives developers and admins a governed way to run, test, and share SOQL-backed data
            views with clear security boundaries and reviewable output.
          </p>
          <div className="actions">
            <Link className="button button-primary" to="/architecture">
              View Architecture
            </Link>
            <a className="button button-secondary" href="https://github.com/jterrats/JT_DynamicQueries">
              Repository
            </a>
          </div>
        </section>

        <section className="section-grid">
          <div className="section-heading">
            <p className="eyebrow">Product Surface</p>
            <h2>Designed for real debugging and access validation.</h2>
          </div>
          <div className="card-grid">
            {capabilities.map((item) => (
              <article className="card" key={item.title}>
                <h3>{item.title}</h3>
                <p>{item.body}</p>
              </article>
            ))}
          </div>
        </section>

        <section className="section-grid">
          <div className="section-heading">
            <p className="eyebrow">Core Flow</p>
            <h2>From configuration to inspected records.</h2>
          </div>
          <ol className="timeline">
            {flows.map((flow, index) => (
              <li key={flow}>
                <span>{index + 1}</span>
                {flow}
              </li>
            ))}
          </ol>
        </section>

        <section className="section-grid" id="demos">
          <div className="section-heading">
            <p className="eyebrow">Demos</p>
            <h2>See the query workflows in motion.</h2>
          </div>
          <div className="demo-grid">
            {demos.map((demo) => (
              <article className="demo-card" key={demo.src}>
                <img src={demo.src} alt={`${demo.title} demo`} loading="lazy" />
                <div>
                  <h3>{demo.title}</h3>
                  <p>{demo.body}</p>
                </div>
              </article>
            ))}
          </div>
        </section>
      </main>
    </Shell>
  );
}

function Architecture() {
  return (
    <Shell>
      <main>
        <section className="page-header">
          <p className="eyebrow">Architecture</p>
          <h1>Layered Salesforce query framework.</h1>
          <p className="lead">
            The runtime separates Lightning UI, Apex entry points, domain services, and Salesforce platform storage so
            query behavior stays testable and deployment-safe.
          </p>
        </section>

        <section className="architecture-map" aria-label="Architecture layers">
          {layers.map((layer, index) => (
            <article className="layer-card" key={layer.name}>
              <span>{String(index + 1).padStart(2, '0')}</span>
              <h2>{layer.name}</h2>
              <p>{layer.details}</p>
            </article>
          ))}
        </section>

        <section className="section-grid">
          <div className="section-heading">
            <p className="eyebrow">Security Model</p>
            <h2>Explicit execution modes keep risk visible.</h2>
          </div>
          <div className="split-panel">
            <article>
              <h3>User Mode</h3>
              <p>Use for production-safe reads where CRUD, FLS, and sharing must reflect the active user context.</p>
            </article>
            <article>
              <h3>System Mode</h3>
              <p>Use only for controlled admin workflows where bypass behavior is intentional and documented.</p>
            </article>
          </div>
        </section>

        <section className="section-grid">
          <div className="section-heading">
            <p className="eyebrow">Data Flow</p>
            <h2>Configuration, bindings, query execution, and evidence.</h2>
          </div>
          <div className="flow-diagram" aria-label="Query execution data flow">
            <div>Config Metadata</div>
            <div>Binding Resolver</div>
            <div>Apex Selector</div>
            <div>Salesforce Data</div>
            <div>Result Views</div>
          </div>
        </section>
      </main>
    </Shell>
  );
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/architecture" element={<Architecture />} />
      </Routes>
    </BrowserRouter>
  );
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);

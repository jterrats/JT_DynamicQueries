# Ejemplos de Queries SOQL con Operadores Complejos

Este documento contiene ejemplos de queries SOQL que se probaron durante el desarrollo y ejemplos complejos con operadores mixtos que funcionan con datos reales de Salesforce.

## Queries que se Intentaron Crear (Metadata Configurations)

### 1. Complex Mixed Operators (✅ Corregido - Ahora funciona)

```sql
SELECT Id, Name, Industry, AnnualRevenue, Type, NumberOfEmployees, BillingCountry
FROM Account
WHERE Industry IN :industries
  AND Type != :excludedType
  AND AnnualRevenue >= :minRevenue
  AND AnnualRevenue <= :maxRevenue
  AND (Name LIKE :namePattern OR Industry LIKE :industryPattern)
  AND NumberOfEmployees >= :minEmployees
  AND NumberOfEmployees <= :maxEmployees
  AND BillingCountry NOT IN :excludedCountries
ORDER BY AnnualRevenue DESC
```

**Nota**: Originalmente tenía `BETWEEN`, pero fue corregido para usar `>=` y `<=` que sí están soportados.

**Bindings requeridos**:
- `industries` (List<String>)
- `excludedType` (String)
- `minRevenue` (Decimal)
- `namePattern` (String) - se agregan wildcards automáticamente
- `industryPattern` (String) - se agregan wildcards automáticamente
- `minEmployees` (Integer)
- `maxEmployees` (Integer)
- `excludedCountries` (List<String>)

---

### 2. Multiple IN Operators (✅ Soportado)

```sql
SELECT Id, Name, Industry, Type, BillingState
FROM Account
WHERE Id IN :accountIds
  AND Industry IN :validIndustries
  AND Type IN :accountTypes
  AND BillingState IN :validStates
  AND Name NOT IN :excludedNames
ORDER BY Name
```

**Bindings requeridos**:
- `accountIds` (List<Id>)
- `validIndustries` (List<String>)
- `accountTypes` (List<String>)
- `validStates` (List<String>)
- `excludedNames` (List<String>)

---

### 3. All Comparison Operators (✅ Soportado)

```sql
SELECT Id, Name, AnnualRevenue, CreatedDate, NumberOfEmployees
FROM Account
WHERE AnnualRevenue = :exactRevenue
   OR AnnualRevenue != :notEqualRevenue
   OR AnnualRevenue < :lessThanRevenue
   OR AnnualRevenue <= :lessThanOrEqual
   OR AnnualRevenue > :greaterThanRevenue
   OR AnnualRevenue >= :greaterThanOrEqual
   OR CreatedDate = :exactDate
   OR NumberOfEmployees <> :notEqualEmployees
LIMIT 100
```

**Bindings requeridos**:
- `exactRevenue` (Decimal)
- `notEqualRevenue` (Decimal)
- `lessThanRevenue` (Decimal)
- `lessThanOrEqual` (Decimal)
- `greaterThanRevenue` (Decimal)
- `greaterThanOrEqual` (Decimal)
- `exactDate` (Date)
- `notEqualEmployees` (Integer)

---

### 4. LIKE Patterns Mixed (✅ Soportado)

```sql
SELECT Id, Name, Website, Phone
FROM Account
WHERE (Name LIKE :startsWith OR Name LIKE :endsWith)
  AND Website LIKE :websitePattern
  AND Phone LIKE :phonePattern
  AND Description LIKE :descriptionKeyword
ORDER BY Name
LIMIT 50
```

**Bindings requeridos**:
- `startsWith` (String) - se agregan wildcards automáticamente
- `endsWith` (String) - se agregan wildcards automáticamente
- `websitePattern` (String) - se agregan wildcards automáticamente
- `phonePattern` (String) - se agregan wildcards automáticamente
- `descriptionKeyword` (String) - se agregan wildcards automáticamente

---

### 5. NOT Operators Test (❌ Contiene NOT LIKE - No soportado)

```sql
SELECT Id, Name, Industry, Type
FROM Account
WHERE Industry NOT IN :excludedIndustries
  AND Type != :excludedType
  AND AnnualRevenue NOT IN :excludedRevenues
  AND Name NOT LIKE :excludedPattern  -- ❌ NO SOPORTADO
  AND BillingCountry <> :excludedCountry
ORDER BY Name
```

**Problema**: Usa `NOT LIKE` que no está soportado por la validación.

**Bindings requeridos**:
- `excludedIndustries` (List<String>)
- `excludedType` (String)
- `excludedRevenues` (List<Decimal>)
- `excludedPattern` (String)
- `excludedCountry` (String)

---

## Ejemplos de Queries Complejas que Funcionan (Con Datos Reales)

### Ejemplo 1: Account con Múltiples Operadores (✅ Funciona)

```sql
SELECT Id, Name, Industry, AnnualRevenue, Type, NumberOfEmployees, BillingCountry, CreatedDate
FROM Account
WHERE Industry IN :industries
  AND Type != :excludedType
  AND AnnualRevenue >= :minRevenue
  AND AnnualRevenue <= :maxRevenue
  AND (Name LIKE :namePattern OR Industry LIKE :industryPattern)
  AND NumberOfEmployees >= :minEmployees
  AND NumberOfEmployees <= :maxEmployees
  AND BillingCountry NOT IN :excludedCountries
  AND CreatedDate >= :startDate
ORDER BY AnnualRevenue DESC
LIMIT 100
```

**Bindings de ejemplo (que devuelven resultados)**:
```json
{
  "industries": ["Technology", "Finance", "Healthcare"],
  "excludedType": "Competitor",
  "minRevenue": 1000000,
  "maxRevenue": 100000000,
  "namePattern": "Acme",
  "industryPattern": "Tech",
  "minEmployees": 10,
  "maxEmployees": 1000,
  "excludedCountries": ["Test Country"],
  "startDate": "2020-01-01"
}
```

**Nota**: `namePattern` y `industryPattern` se convierten automáticamente a `%Acme%` y `%Tech%` respectivamente.

---

### Ejemplo 2: Contact con Operadores Mixtos (✅ Funciona)

```sql
SELECT Id, FirstName, LastName, Email, Phone, AccountId, Account.Name, CreatedDate
FROM Contact
WHERE AccountId IN :accountIds
  AND (FirstName LIKE :firstNamePattern OR LastName LIKE :lastNamePattern)
  AND Email != :excludedEmail
  AND Phone != null
  AND CreatedDate >= :startDate
  AND CreatedDate <= :endDate
  AND Account.Industry IN :accountIndustries
ORDER BY LastName, FirstName
LIMIT 200
```

**Bindings de ejemplo**:
```json
{
  "accountIds": ["001000000000000AAA", "001000000000000BBB"],
  "firstNamePattern": "John",
  "lastNamePattern": "Smith",
  "excludedEmail": "test@example.com",
  "startDate": "2023-01-01",
  "endDate": "2024-12-31",
  "accountIndustries": ["Technology", "Finance"]
}
```

**Nota**: Si no tienes Account IDs específicos, puedes usar una subquery:
```sql
WHERE AccountId IN (SELECT Id FROM Account WHERE Industry IN :accountIndustries)
```

---

### Ejemplo 3: Opportunity con Comparaciones Numéricas y Fechas (✅ Funciona)

```sql
SELECT Id, Name, Amount, StageName, CloseDate, AccountId, Account.Name, CreatedDate
FROM Opportunity
WHERE Amount >= :minAmount
  AND Amount <= :maxAmount
  AND StageName IN :validStages
  AND StageName != :excludedStage
  AND CloseDate >= :startCloseDate
  AND CloseDate <= :endCloseDate
  AND Account.Industry IN :accountIndustries
  AND (Name LIKE :namePattern OR Account.Name LIKE :accountNamePattern)
ORDER BY Amount DESC, CloseDate DESC
LIMIT 100
```

**Bindings de ejemplo**:
```json
{
  "minAmount": 10000,
  "maxAmount": 1000000,
  "validStages": ["Closed Won", "Negotiation/Review"],
  "excludedStage": "Closed Lost",
  "startCloseDate": "2024-01-01",
  "endCloseDate": "2024-12-31",
  "accountIndustries": ["Technology", "Finance"],
  "namePattern": "Enterprise",
  "accountNamePattern": "Acme"
}
```

---

### Ejemplo 4: Lead con Operadores Complejos (✅ Funciona)

```sql
SELECT Id, FirstName, LastName, Email, Company, Industry, Status, CreatedDate, Rating
FROM Lead
WHERE Industry IN :industries
  AND Industry != :excludedIndustry
  AND Status IN :validStatuses
  AND Status != :excludedStatus
  AND (FirstName LIKE :firstNamePattern OR LastName LIKE :lastNamePattern OR Company LIKE :companyPattern)
  AND Email != null
  AND Rating IN :validRatings
  AND CreatedDate >= :startDate
ORDER BY CreatedDate DESC, Company
LIMIT 150
```

**Bindings de ejemplo**:
```json
{
  "industries": ["Technology", "Finance", "Healthcare"],
  "excludedIndustry": "Other",
  "validStatuses": ["Open - Not Contacted", "Working - Contacted"],
  "excludedStatus": "Unqualified",
  "firstNamePattern": "John",
  "lastNamePattern": "Doe",
  "companyPattern": "Corp",
  "validRatings": ["Hot", "Warm"],
  "startDate": "2024-01-01"
}
```

---

### Ejemplo 5: Account con Subquery y Operadores Mixtos (✅ Funciona)

```sql
SELECT Id, Name, Industry, AnnualRevenue, Type, NumberOfEmployees,
       (SELECT Id, FirstName, LastName, Email FROM Contacts WHERE Email != null),
       (SELECT Id, Name, Amount, StageName FROM Opportunities WHERE StageName IN :validStages)
FROM Account
WHERE Industry IN :industries
  AND Type != :excludedType
  AND AnnualRevenue >= :minRevenue
  AND AnnualRevenue <= :maxRevenue
  AND (Name LIKE :namePattern OR Industry LIKE :industryPattern)
  AND NumberOfEmployees >= :minEmployees
  AND NumberOfEmployees <= :maxEmployees
  AND CreatedDate >= :startDate
ORDER BY AnnualRevenue DESC NULLS LAST
LIMIT 50
```

**Bindings de ejemplo**:
```json
{
  "industries": ["Technology", "Finance"],
  "excludedType": "Competitor",
  "minRevenue": 500000,
  "maxRevenue": 50000000,
  "namePattern": "Acme",
  "industryPattern": "Tech",
  "minEmployees": 5,
  "maxEmployees": 500,
  "validStages": ["Closed Won", "Negotiation/Review"],
  "startDate": "2020-01-01"
}
```

---

## Operadores Soportados

### ✅ Operadores Soportados

- `=` (igual)
- `!=` o `<>` (diferente)
- `<` (menor que)
- `<=` (menor o igual)
- `>` (mayor que)
- `>=` (mayor o igual)
- `IN` (en lista)
- `NOT IN` (no en lista)
- `LIKE` (patrón de texto) - con wildcards automáticos
- `AND` (y lógico)
- `OR` (o lógico)
- `NULL` / `!= null` (verificación de nulos)

### ❌ Operadores NO Soportados

- `BETWEEN` - No soportado (usar `>=` y `<=` en su lugar)
- `NOT LIKE` - No soportado (usar `NOT IN` con lista o lógica alternativa)

---

## Notas Importantes

1. **Wildcards Automáticos para LIKE**: El sistema automáticamente agrega `%` al inicio y final de los valores en bindings usados con `LIKE`, a menos que el valor ya contenga `%` o `_`.

2. **Conversión de Tipos**: Los bindings se convierten automáticamente al tipo correcto según el operador y el campo:
   - `IN` / `NOT IN` → Listas del tipo apropiado
   - Comparaciones numéricas → Decimal, Integer, etc.
   - Comparaciones de fecha → Date, DateTime

3. **Seguridad**: Todas las queries respetan Field-Level Security (FLS) y Object-Level Security (OLS) cuando `enforceSecurity = true`.

4. **Performance**: Para queries grandes, considera usar:
   - `LIMIT` apropiado
   - `getRecordsWithAutoStrategy()` para procesamiento en lotes
   - `processRecordsWithCursor()` para procesamiento con cursor

---

## Ejemplos de Bindings JSON

### Para Account con múltiples operadores:
```json
{
  "industries": ["Technology", "Finance", "Healthcare"],
  "excludedType": "Competitor",
  "minRevenue": 1000000,
  "maxRevenue": 100000000,
  "namePattern": "Acme",
  "industryPattern": "Tech",
  "minEmployees": 10,
  "maxEmployees": 1000,
  "excludedCountries": ["Test Country"],
  "startDate": "2020-01-01"
}
```

### Para Contact con relaciones:
```json
{
  "accountIds": ["001000000000000AAA"],
  "firstNamePattern": "John",
  "lastNamePattern": "Smith",
  "excludedEmail": "test@example.com",
  "startDate": "2023-01-01",
  "endDate": "2024-12-31",
  "accountIndustries": ["Technology"]
}
```

### Para Opportunity con fechas y montos:
```json
{
  "minAmount": 10000,
  "maxAmount": 1000000,
  "validStages": ["Closed Won", "Negotiation/Review"],
  "excludedStage": "Closed Lost",
  "startCloseDate": "2024-01-01",
  "endCloseDate": "2024-12-31",
  "accountIndustries": ["Technology"],
  "namePattern": "Enterprise",
  "accountNamePattern": "Acme"
}
```

---

## Cómo Probar Estas Queries

1. **Crear la configuración de metadata** usando el Setup Wizard o directamente en Custom Metadata Types
2. **Ejecutar la query** desde Query Viewer con los bindings apropiados
3. **Verificar resultados** - las queries deberían devolver resultados si hay datos que coincidan con los criterios

---

## Referencias

- [Salesforce SOQL Documentation](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/)
- [JT_DataSelector.cls](../force-app/main/default/classes/JT_DataSelector.cls) - Clase principal para ejecutar queries
- [JT_QueryBindingUtil.cls](../force-app/main/default/classes/JT_QueryBindingUtil.cls) - Utilidades para procesar bindings


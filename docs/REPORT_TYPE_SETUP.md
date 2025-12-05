# Report Type Setup Instructions

## Overview

Custom Metadata Types cannot have Report Types deployed via Metadata API. Follow these manual steps to create a report type for `JT_DynamicQueryConfiguration__mdt`.

## Steps to Create Report Type

### 1. Navigate to Setup

- From Setup, enter "Report Types" in the Quick Find box
- Select **Report Types**

### 2. Create New Custom Report Type

- Click **New Custom Report Type**
- Select **Custom Metadata Type** as the primary object
- Select **JT Dynamic Query Configuration** as the specific custom metadata type

### 3. Configure Report Type

Fill in the following details:

| Field             | Value                                                                |
| ----------------- | -------------------------------------------------------------------- |
| Report Type Label | Dynamic Query Configurations                                         |
| Report Type Name  | JT_Dynamic_Query_Configurations                                      |
| Description       | Report on Dynamic Query Configurations with filtering by Object Name |
| Store in Category | Other Reports                                                        |
| Deployment Status | Deployed                                                             |

### 4. Define Report Layout

Click **Next** and configure the fields:

#### Columns to Include (checked by default):

- ✅ Label
- ✅ Developer Name
- ✅ Object Name (JT_ObjectName\_\_c)
- ☐ Base Query (JT_BaseQuery\_\_c)
- ☐ Binding (JT_Binding\_\_c)
- ☐ Field Mappings (JT_FieldMappings\_\_c)

### 5. Save and Deploy

- Click **Save**
- The report type is now available for use

## Creating Reports

### Example 1: All Configurations by Object

1. Navigate to **Reports** tab
2. Click **New Report**
3. Select **Dynamic Query Configurations**
4. Add filters:
   - **Object Name** equals `Account`
5. Group by **Object Name**
6. Save the report

### Example 2: Configuration Inventory

1. Create a new report using **Dynamic Query Configurations**
2. Add columns:
   - Label
   - Developer Name
   - Object Name
3. Group by **Object Name**
4. Sort by **Developer Name**
5. Save as "Dynamic Query Inventory"

## Notes

- Report Types for Custom Metadata are read-only
- Users need the **JT_Dynamic_Queries** permission set to access configurations
- The **Reports** tab is already included in the custom app
- Use reports to audit and document your query configurations

## Alternative: Direct Custom Metadata Access

If you don't need reporting functionality, you can access configurations directly:

1. Setup → Custom Metadata Types → JT Dynamic Query Configuration
2. Click **Manage Records**
3. View and filter configurations

---

_This setup is required only once per org_

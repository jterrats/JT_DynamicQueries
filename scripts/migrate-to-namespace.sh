#!/bin/bash

# Script to migrate codebase from no-namespace to namespace
# This prepares the code for AppExchange Managed Package

set -e

NAMESPACE="${1:-JTDynamicQueries}"

if [ -z "$NAMESPACE" ]; then
    echo "❌ Error: Namespace is required"
    echo "Usage: $0 <namespace>"
    echo "Example: $0 JTDynamicQueries"
    exit 1
fi

echo "========================================="
echo "Namespace Migration Script"
echo "========================================="
echo "Namespace: $NAMESPACE"
echo ""
echo "⚠️  WARNING: This will modify your codebase!"
echo "   Make sure you're on a feature branch"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Create backup
echo "📦 Creating backup..."
BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r force-app "$BACKUP_DIR/"
echo "✓ Backup created: $BACKUP_DIR"
echo ""

# Function to replace in file
replace_in_file() {
    local file=$1
    local search=$2
    local replace=$3

    if [ -f "$file" ]; then
        # Use different sed syntax for macOS vs Linux
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|$search|$replace|g" "$file"
        else
            sed -i "s|$search|$replace|g" "$file"
        fi
    fi
}

echo "🔄 Starting migration..."
echo ""

# 1. Update sfdx-project.json
echo "1. Updating sfdx-project.json..."
replace_in_file "sfdx-project.json" '"namespace": ""' "\"namespace\": \"$NAMESPACE\""
echo "   ✓ Updated namespace in sfdx-project.json"
echo ""

# 2. Update Custom Objects (__c)
echo "2. Updating Custom Object references..."
find force-app/main/default -type f \( -name "*.cls" -o -name "*.js" -o -name "*.html" -o -name "*.xml" \) | while read file; do
    # JT_RunAsTest_Execution__c -> JTDynamicQueries__RunAsTest_Execution__c
    replace_in_file "$file" "JT_RunAsTest_Execution__c" "${NAMESPACE}__RunAsTest_Execution__c"
    replace_in_file "$file" "JT_SettingsAuditLog__c" "${NAMESPACE}__SettingsAuditLog__c"
    replace_in_file "$file" "JT_ErrorLog__c" "${NAMESPACE}__ErrorLog__c"
    replace_in_file "$file" "JT_DynamicQuerySettings__c" "${NAMESPACE}__DynamicQuerySettings__c"
done
echo "   ✓ Updated Custom Object references"
echo ""

# 3. Update Custom Metadata Types (__mdt)
echo "3. Updating Custom Metadata Type references..."
find force-app/main/default -type f \( -name "*.cls" -o -name "*.js" -o -name "*.html" -o -name "*.xml" \) | while read file; do
    replace_in_file "$file" "JT_DynamicQueryConfiguration__mdt" "${NAMESPACE}__DynamicQueryConfiguration__mdt"
    replace_in_file "$file" "JT_SystemSettings__mdt" "${NAMESPACE}__SystemSettings__mdt"
done
echo "   ✓ Updated Custom Metadata Type references"
echo ""

# 4. Update Custom Fields (__c in queries and code)
echo "4. Updating Custom Field references..."
find force-app/main/default -type f \( -name "*.cls" -o -name "*.js" \) | while read file; do
    replace_in_file "$file" "JT_BaseQuery__c" "${NAMESPACE}__BaseQuery__c"
    replace_in_file "$file" "JT_Binding__c" "${NAMESPACE}__Binding__c"
    replace_in_file "$file" "JT_ObjectName__c" "${NAMESPACE}__ObjectName__c"
done
echo "   ✓ Updated Custom Field references"
echo ""

# 5. Update Apex Class references (JT_ClassName -> Namespace.ClassName)
echo "5. Updating Apex Class references..."
# Note: This is complex - Apex classes with namespace use dot notation
# JT_DataSelector -> JTDynamicQueries.DataSelector
find force-app/main/default -type f \( -name "*.cls" -o -name "*.js" \) | while read file; do
    # Update @salesforce/apex imports
    replace_in_file "$file" "@salesforce/apex/JT_" "@salesforce/apex/${NAMESPACE}."

    # Update class names in comments/documentation
    # This is a simplified version - may need manual review
done
echo "   ✓ Updated Apex Class references"
echo "   ⚠️  Note: Class names in Apex code need manual review"
echo ""

# 6. Update Custom Labels
echo "6. Updating Custom Label references..."
find force-app/main/default/lwc -type f -name "*.js" | while read file; do
    replace_in_file "$file" "@salesforce/label/c.JT_" "@salesforce/label/c.${NAMESPACE}__JT_"
done
echo "   ✓ Updated Custom Label references"
echo ""

# 7. Update LWC component references
echo "7. Updating LWC component references..."
find force-app/main/default/lwc -type f -name "*.html" | while read file; do
    replace_in_file "$file" "c-jt-" "c-${NAMESPACE,,}-jt-"
done
echo "   ✓ Updated LWC component references"
echo ""

# 8. Update Permission Set
echo "8. Updating Permission Set..."
find force-app/main/default/permissionsets -type f -name "*.xml" | while read file; do
    replace_in_file "$file" "<apexClass>JT_" "<apexClass>${NAMESPACE}."
    replace_in_file "$file" "<object>JT_" "<object>${NAMESPACE}__"
done
echo "   ✓ Updated Permission Set"
echo ""

# 9. Update metadata XML files
echo "9. Updating metadata XML files..."
find force-app/main/default -type f -name "*.xml" | while read file; do
    # Update object references in layouts, etc.
    replace_in_file "$file" "JT_RunAsTest_Execution__c" "${NAMESPACE}__RunAsTest_Execution__c"
    replace_in_file "$file" "JT_SettingsAuditLog__c" "${NAMESPACE}__SettingsAuditLog__c"
    replace_in_file "$file" "JT_ErrorLog__c" "${NAMESPACE}__ErrorLog__c"
done
echo "   ✓ Updated metadata XML files"
echo ""

echo "========================================="
echo "✅ Migration Complete!"
echo "========================================="
echo ""
echo "⚠️  IMPORTANT: Manual Review Required"
echo ""
echo "1. Review Apex class names:"
echo "   - Classes should be: ${NAMESPACE}.ClassName"
echo "   - But internal references may need adjustment"
echo ""
echo "2. Test in scratch org:"
echo "   sf org create scratch --definition-file config/project-scratch-def.json"
echo "   sf project deploy start"
echo ""
echo "3. Verify all references:"
echo "   grep -r 'JT_' force-app --exclude-dir=backup-*"
echo ""
echo "4. Update documentation:"
echo "   - README.md"
echo "   - Installation guides"
echo "   - API documentation"
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""


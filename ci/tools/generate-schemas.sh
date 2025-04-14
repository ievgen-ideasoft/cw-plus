#!/bin/bash
# Script to generate schemas for CosmWasm contracts

set -e

# Find all contract directories
for contract_dir in $(find ./contracts -maxdepth 1 -type d | grep -v "^./contracts$"); do
  contract_name=$(basename $contract_dir)
  echo "Generating schema for $contract_name"
  
  # Create schema directory if it doesn't exist
  mkdir -p "$contract_dir/schema"
  
  # Try to extract message structs from the contract
  query_msg_file="$contract_dir/src/msg.rs"
  
  if [ -f "$query_msg_file" ]; then
    echo "  Found message file: $query_msg_file"
    
    # Create basic schema files for common message types
    for msg_type in "InstantiateMsg" "ExecuteMsg" "QueryMsg"; do
      if grep -q "pub struct $msg_type" "$query_msg_file" || grep -q "pub enum $msg_type" "$query_msg_file"; then
        echo "  Found $msg_type definition"
        
        # Create a basic JSON schema file
        cat > "$contract_dir/schema/${msg_type,,}.json" << EOF
{
  "title": "$contract_name $msg_type Schema",
  "description": "Auto-generated schema for $msg_type",
  "type": "object",
  "required": [],
  "properties": {}
}
EOF
        echo "  Created schema for $msg_type"
      fi
    done
  else
    echo "  No message file found at $query_msg_file"
    
    # Create a generic schema file
    cat > "$contract_dir/schema/schema.json" << EOF
{
  "title": "$contract_name Schema",
  "description": "Auto-generated placeholder schema",
  "type": "object",
  "required": [],
  "properties": {}
}
EOF
    echo "  Created placeholder schema"
  fi
done

echo "Schema generation complete"
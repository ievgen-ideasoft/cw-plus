#!/bin/bash
# Custom CosmWasm security scanning script
# Adjusted for compatibility with older bash versions

set -e

CONTRACTS_DIR="./contracts"
REPORT_FILE="cosmwasm-security-report.md"

echo "# CosmWasm Security Scan Report" > $REPORT_FILE
echo "Generated on $(date)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Find all contract directories
for contract_dir in $(find $CONTRACTS_DIR -maxdepth 1 -type d | grep -v "^$CONTRACTS_DIR\$"); do
  contract_name=$(basename $contract_dir)
  echo "## Scanning contract: $contract_name" >> $REPORT_FILE
  
  # Check for known security patterns
  echo "### Code Pattern Analysis" >> $REPORT_FILE
  
  # Check for unchecked arithmetic
  unchecked_math=$(grep -r --include="*.rs" "\.\(add\|sub\|mul\|div\)(.*)" $contract_dir/src | grep -v "checked_" | wc -l)
  if [ $unchecked_math -gt 0 ]; then
    echo "- ⚠️ **WARNING**: Found $unchecked_math potentially unchecked arithmetic operations" >> $REPORT_FILE
    echo "  - Consider using checked_add, checked_sub, etc. to prevent overflow/underflow" >> $REPORT_FILE
    # Show examples
    echo "  - Examples:" >> $REPORT_FILE
    grep -r --include="*.rs" "\.\(add\|sub\|mul\|div\)(.*)" $contract_dir/src | grep -v "checked_" | head -5 | sed 's/^/    - /' >> $REPORT_FILE
  else
    echo "- ✅ No unchecked arithmetic operations found" >> $REPORT_FILE
  fi
  
  # Check for panic!/unwrap/expect
  panics=$(grep -r --include="*.rs" -E "panic!|\.unwrap\(|\.expect\(" $contract_dir/src | wc -l)
  if [ $panics -gt 0 ]; then
    echo "- ⚠️ **WARNING**: Found $panics panic!/unwrap/expect usages" >> $REPORT_FILE
    echo "  - These should be avoided in production contracts, use proper error handling instead" >> $REPORT_FILE
    # Show examples
    echo "  - Examples:" >> $REPORT_FILE
    grep -r --include="*.rs" -E "panic!|\.unwrap\(|\.expect\(" $contract_dir/src | head -5 | sed 's/^/    - /' >> $REPORT_FILE
  else
    echo "- ✅ No panic!/unwrap/expect found" >> $REPORT_FILE
  fi
  
  # Check for unsafe blocks
  unsafe_blocks=$(grep -r --include="*.rs" "unsafe {" $contract_dir/src | wc -l)
  if [ $unsafe_blocks -gt 0 ]; then
    echo "- ⚠️ **WARNING**: Found $unsafe_blocks unsafe blocks" >> $REPORT_FILE
    echo "  - Unsafe code should be thoroughly reviewed and documented" >> $REPORT_FILE
    # Show examples
    echo "  - Examples:" >> $REPORT_FILE
    grep -r --include="*.rs" -A 3 "unsafe {" $contract_dir/src | head -10 | sed 's/^/    - /' >> $REPORT_FILE
  else
    echo "- ✅ No unsafe blocks found" >> $REPORT_FILE
  fi

  # Check for debug assertions or asserts
  debug_asserts=$(grep -r --include="*.rs" -E "assert!|assert_eq!|debug_assert!" $contract_dir/src | wc -l)
  if [ $debug_asserts -gt 0 ]; then
    echo "- ⚠️ **WARNING**: Found $debug_asserts assert!/assert_eq!/debug_assert! usages" >> $REPORT_FILE
    echo "  - These might cause panics in production code" >> $REPORT_FILE
  else
    echo "- ✅ No assert macros found" >> $REPORT_FILE
  fi
  
  # Contract size
  echo "### Contract Size Analysis" >> $REPORT_FILE
  target_dir="target/wasm32-unknown-unknown/release"
  wasm_file="$target_dir/$(echo $contract_name | tr '-' '_').wasm"
  
  # Count lines of code as a size metric (more reliable than trying to build)
  lines=$(find $contract_dir/src -name "*.rs" | xargs cat | wc -l)
  echo "- Source code: $lines lines" >> $REPORT_FILE
  
  if [ $lines -gt 2000 ]; then
    echo "  - ⚠️ **WARNING**: Contract source is large (>2000 lines), may be complex" >> $REPORT_FILE
  elif [ $lines -gt 1000 ]; then
    echo "  - 🔶 **NOTICE**: Contract source is medium size (>1000 lines)" >> $REPORT_FILE
  else
    echo "  - ✅ Contract source size is reasonable" >> $REPORT_FILE
  fi
  
  echo "" >> $REPORT_FILE
done

echo "Security scan complete! Report saved to $REPORT_FILE"
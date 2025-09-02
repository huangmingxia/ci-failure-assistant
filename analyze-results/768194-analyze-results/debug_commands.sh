#!/bin/bash
# Debug Commands for Launch 768194 Failures
# Generated: September 2, 2024

echo "=== CI Failure Debug Commands - Launch 768194 ==="
echo "Runtime Panic Issues (OCP-22760, 23165, 25310, 33374, 39747)"
echo "AWS Environment Issues (OCP-40825)"
echo ""

# Runtime Panic Debugging
echo "=== Runtime Panic Investigation ==="
echo "# Check current image format in cluster"
echo "oc get clusterversion -o jsonpath='{.status.desired.image}'"
echo ""
echo "# Extract version properly"
echo "oc get clusterversion -o jsonpath='{.status.desired.version}'"
echo ""
echo "# Check cluster info"
echo "oc get clusterversion -o yaml"
echo ""

# AWS Environment Debugging
echo "=== AWS Environment Investigation ==="
echo "# Check for contaminated IAM resources"
echo "aws iam get-user --user-name hive_40825user"
echo "aws iam list-roles --path-prefix /hive_40825"
echo ""
echo "# Clean up contaminated resources"
echo "aws iam delete-user --user-name hive_40825user"
echo "aws iam delete-role --role-name hive_40825role"
echo "aws iam delete-role --role-name hive_40825csrole"
echo ""

# Hive Operator Status
echo "=== Hive Operator Health Check ==="
echo "# Check Hive installation"
echo "oc get clusterdeployments -A"
echo "oc get hiveconfig cluster -o yaml"
echo "oc get pods -n hive -l control-plane=hive-operator"
echo ""
echo "# Check AssumeRole configuration"
echo "oc get hiveconfig cluster -o yaml | grep -A 10 credentialsSecretRef"
echo "oc get clusterdeployment -o yaml | grep -A 5 credentialsAssumeRole"
echo ""

# Test Framework Investigation
echo "=== Test Framework Analysis ==="
echo "# Check test code location"
echo "find /Users/mihuang/go/src/github.com/openshift/openshift-tests-private -name '*hive*' -type f"
echo "grep -r 'extractRelFromImg' /Users/mihuang/go/src/github.com/openshift/openshift-tests-private/test/extended/cluster_operator/hive/"
echo ""
echo "# Check for panic patterns"
echo "grep -r 'index out of range' /Users/mihuang/AI/ci-failure-assistant/failed_cases_768194/logs/"
echo ""

# Environment Validation
echo "=== Environment Validation ==="
echo "# Check CI configuration"
echo "./check_config.sh"
echo ""
echo "# Verify log retrieval"
echo "ls -la failed_cases_768194/logs/"
echo ""
echo "# Check image formats in logs"
echo "grep -h 'registry.*@sha256' failed_cases_768194/logs/*.log"
echo ""

echo "=== Quick Fixes ==="
echo "# Runtime Panic Fix (add to hive_util.go)"
cat << 'EOF'
func extractRelFromImg(image string) string {
    // Handle digest-based references
    if strings.Contains(image, "@sha256:") {
        // Fallback to cluster version API
        return getVersionFromClusterAPI()
    }
    // Existing tag-based parsing logic...
    // Add validation before array access
    if len(parts) < 2 {
        return ""
    }
}
EOF
echo ""

echo "# AWS Environment Cleanup Script"
cat << 'EOF'
#!/bin/bash
# Clean AWS test environment
USER_NAME="hive_40825user"
ROLE_NAMES=("hive_40825role" "hive_40825csrole")

echo "Cleaning up AWS test resources..."
aws iam delete-user --user-name $USER_NAME 2>/dev/null && echo "Deleted user: $USER_NAME"
for role in "${ROLE_NAMES[@]}"; do
    aws iam delete-role --role-name $role 2>/dev/null && echo "Deleted role: $role"
done
echo "Cleanup complete."
EOF

echo ""
echo "=== End Debug Commands ==="
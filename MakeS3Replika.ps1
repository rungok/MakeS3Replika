#!/usr/bin/env powershell
# some bash-declaration: set -euo pipefail

# ========= Edit these =========
$FB_A="bil-pure1.oob.local"
$FB_B="osl-pure2.oob.local"

$ACCOUNT_A="ST4822"
$ACCOUNT_B="ST4822"
$BUCKET_A="bucket-a"
$BUCKET_B="bucket-b"
$APIUSER="rungok"

# How each array refers to the other (array S3 connection name)
$REMOTE_ON_A="no-west.s3.dustin.com"
$REMOTE_ON_B="no-east.s3.dustin.com"

# Replication users’ S3 keys
# A will push to B using B’s replication user credentials:
$B_REPL_ACCESS_KEY="PSFBSAZRHGIPKILMHJLYJPIBNABADIODMAOFCJHLF"
# Secret will be entered interactively (CLI prompts)

# B will push to A using A’s replication user credentials:
$A_REPL_ACCESS_KEY="PSFBSAZRHGIPKILMHJLYJPIBNABADIPDNAODCJHLL"
# Secret will be entered interactively (CLI prompts)

# Optional: a friendly name for each “remote credentials” object
$CREDS_ON_A="$REMOTE_ON_A/replication-creds-for-b"
$CREDS_ON_B="$REMOTE_ON_B/replication-creds-for-a"

# ========= Create buckets (on each array) =========
ssh $APIUSER@$FB_A "purebucket create --account $ACCOUNT_A $BUCKET_A"
ssh $APIUSER@$FB_B "purebucket create --account $ACCOUNT_B $BUCKET_B"
# (Bucket create syntax reference) ⁵

# ========= Create remote credentials (each side stores the other side’s S3 keys) =========
# On A: store B’s keys (will prompt for Secret Access Key)
ssh -t $APIUSER@$FB_A "pureobj remote-credentials create $CREDS_ON_A --access-key-id '$B_REPL_ACCESS_KEY'"
# On B: store A’s keys (will prompt for Secret Access Key)
ssh -t $APIUSER@$FB_B "pureobj remote-credentials create $CREDS_ON_B --access-key-id '$A_REPL_ACCESS_KEY'"
# (Remote credentials CLI syntax reference)

# ========= Enable S3 versioning on both buckets (required for replication targets) =========
# Use AWS CLI (or any S3 tool) against each array’s S3 data VIP:
aws --endpoint-url http://$REMOTE_ON_A s3api put-bucket-versioning --bucket $BUCKET_A --versioning-configuration Status=Enabled
aws --endpoint-url http://$REMOTE_ON_B s3api put-bucket-versioning --bucket $BUCKET_B --versioning-configuration Status=Enabled
# (Connecting an S3 client and versioning guidance)

# ========= Create replica links in both directions (active-active) =========
# A -> B
ssh $APIUSER@$FB_A "purebucket replica-link create $BUCKET_A --remote-credentials $CREDS_ON_A --remote-bucket $BUCKET_B"
# B -> A
ssh $APIUSER@$FB_B "purebucket replica-link create $BUCKET_B --remote-credentials $CREDS_ON_B --remote-bucket $BUCKET_A"
# (Replica-link create CLI syntax reference)

# ========= (Optional) Check link health =========
ssh $APIUSER@$FB_A "purebucket replica-link list --names $BUCKET_A"
ssh $APIUSER@$FB_B "purebucket replica-link list --names $BUCKET_B"

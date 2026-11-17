# Wallaby RPM publication

The pipeline publishes binary `RPMS/noarch/*.rpm` files to the current Jenkins build's EngCI directory. Source RPM publication is unchanged and remains outside this stage.

`artifact_upload.py` reads the existing `ARTIFACTORY_USER` and Conjur-backed `ARTIFACT_TOKEN` environment variables. Credentials stay out of Groovy interpolation, command arguments, and verbose HTTP logs. The shell disables tracing and propagates a failed uploader exit status.

The uploader requires an HTTP 2xx response for every file. Authentication failures, other unsuccessful HTTP responses, missing files, and an unmatched RPM glob fail publication rather than reporting a successful Jenkins stage. The build number is resolved when the pipeline defines `ARTIFACTORY_URL`; it is not left as a literal shell variable inside another variable.

This change belongs to the canonical `noironetworks/ciscoaci-puppet` repository. It does not require changing the mirror configuration, signing behavior, upload account, or credential reference. Offline HTTP tests for the shared uploader cover successful and rejected uploads without publishing to EngCI.

# Classic menu verification

`test.ps1` checks COM activation, selection handling, menu construction and optional worker execution. `-Registered` checks registration as seen by the test process. These checks do not establish that the desktop Explorer discovers or displays the handler.

## Real Explorer check

1. Build and package the candidate. Launch its installer from the normal desktop Explorer, outside any virtualized development host. Keep the installer and DLL architecture, version and hashes in the test record.
2. Right-click a local JSON file with a Japanese name containing a space. Open **Show more options**, then **Flect**, and run JSON formatting. Check the output values and confirm the original file's hash is unchanged.
3. Select two JSON files and run key sorting from the same menu. Verify that both outputs have sorted keys and that both original files remain unchanged.
4. Convert a PNG to WebP from the actual menu. Decode the output, check its format and dimensions, and confirm that the original PNG remains unchanged.
5. When evaluating an architecture fix, repeat the official-release baseline in the same desktop installation context. Keep “menu absent” distinct from a loader error captured in Explorer; an error from a separate test process is different evidence.

For an unreleased local build, record the desktop user's auto-update setting and disable it during the trial so a newer official installer cannot replace the candidate unexpectedly. Save settings and the official/candidate installers before switching versions, confirm the setting survives each installation, and finish by restoring the intended build. Reopen both Explorer and Flect to verify persistence. Before a complete local acceptance report, also exercise unsupported input, image resizing, video/audio processing and folder compression through the actual menu.

To roll back, close Flect, run the saved official installer from desktop Explorer, and restart Explorer after setup finishes. Reopen Flect to check settings before restoring the recorded auto-update preference. Keep the candidate installer so the same steps can restore it if the official version lacks the required shell support. Do not delete the settings folder or source files as part of this comparison.

If a direct COM test passes but the actual menu is absent, compare the registration visible to the development host with that visible to an application launched by desktop Explorer. MSIX can virtualize registry writes, so an installer succeeding inside such a host does not prove that its registration is visible outside it. Avoid changing shell security settings to compensate for a registration visibility mismatch.

Microsoft documents this behavior in [Flexible virtualization](https://learn.microsoft.com/en-us/windows/msix/desktop/flexible-virtualization).

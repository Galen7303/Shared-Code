0. Restart the Launchpad service to clear any external processes
1. Download Process Explorer (sysinternals) and launch it
2. Load delete_mydata.sql in the db context you built for demo in demo #1. Run the query up to rollback tran (but don't execute rollback tran)
3. Load up sqlriseasy.sql and execute the script
4. Notice the new set of rterm.exe, conhost.exe, and bxlserver.exe processes
5. Now let's run windbg to look at both SQL Server and bxlserver.
6. Detach debuggers and restart launchpad to clear external processes
7. Load up R Studio and open localcompute.r. Talk about what is in the script. Highlight all the lines and run it.
8. Notice in process explorer there are no processes created by launchpad. What happens is that the query is executed against SQL Server, all the rows are brought back to the client, and then the R langauge commands are executed.
9. Do the same for sqlcompute.r. Look at process explorer and talk about the difference (which is that we call sp_execute_external_script)

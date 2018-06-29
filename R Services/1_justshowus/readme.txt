1. Run prepdemo.cmd
2. Run sqlriseasy_ddl.sql in any database
3. Run sqlriseasy.sql in the db context you ran the above script
4. Notice the error points to the need to run sp_configure
5. Run turnonsqlr.sql
6. Shutdown and start the SQL Server instance
7. Run sqlriseasy.sql again. Notice another error
8. Start the Launchpad server
9. Run sqlriseasy.sql again. Show a few things about the script but we will show details later
10. Show and run helloworld.sql
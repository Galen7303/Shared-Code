Add-OdbcDsn `
	-Name DSC `
	-DriverName 'SQL Server' `
	-Platform '32-bit' `
	-DsnType System `
	-SetPropertyValue @('Description=DSC Pull Server', "Server=GIG01SRVDSCMAN1", 'Trusted_Connection=yes', 'Database=DSC') `
	-PassThru
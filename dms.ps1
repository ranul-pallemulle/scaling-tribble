param ($serverName, $databaseName, $username, $password)

$query = @"

-- START SCRIPT

IF OBJECT_ID(N'[__TesseractEFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__TesseractEFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___TesseractEFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
GO

CREATE TABLE [Configurations] (
    [Id] uniqueidentifier NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    CONSTRAINT [PK_Configurations] PRIMARY KEY ([Id])
);
GO

CREATE TABLE [Skus] (
    [Id] uniqueidentifier NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    CONSTRAINT [PK_Skus] PRIMARY KEY ([Id])
);
GO

CREATE TABLE [ConfigurationVersions] (
    [Id] uniqueidentifier NOT NULL,
    [Version] int NOT NULL,
    [ConfigurationId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_ConfigurationVersions] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_ConfigurationVersions_Configurations_ConfigurationId] FOREIGN KEY ([ConfigurationId]) REFERENCES [Configurations] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [SkuVariants] (
    [Id] uniqueidentifier NOT NULL,
    [SkuId] uniqueidentifier NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [ConfigurationVersionId] uniqueidentifier NULL,
    CONSTRAINT [PK_SkuVariants] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_SkuVariants_ConfigurationVersions_ConfigurationVersionId] FOREIGN KEY ([ConfigurationVersionId]) REFERENCES [ConfigurationVersions] ([Id]),
    CONSTRAINT [FK_SkuVariants_Skus_SkuId] FOREIGN KEY ([SkuId]) REFERENCES [Skus] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [Tenants] (
    [Id] uniqueidentifier NOT NULL,
    [Status] varchar(50) NOT NULL,
    [ConfigurationVersionId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Tenants] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Tenants_ConfigurationVersions_ConfigurationVersionId] FOREIGN KEY ([ConfigurationVersionId]) REFERENCES [ConfigurationVersions] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [SkuVariantVersions] (
    [Id] uniqueidentifier NOT NULL,
    [Version] int NOT NULL,
    [Template] nvarchar(max) NOT NULL,
    [Parameters] nvarchar(4000) NOT NULL,
    [SkuVariantId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_SkuVariantVersions] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_SkuVariantVersions_SkuVariants_SkuVariantId] FOREIGN KEY ([SkuVariantId]) REFERENCES [SkuVariants] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [TenantResources] (
    [Id] uniqueidentifier NOT NULL,
    [NameId] nvarchar(4000) NOT NULL,
    [Status] varchar(50) NOT NULL,
    [SkuVariantId] uniqueidentifier NOT NULL,
    [TenantId] uniqueidentifier NULL,
    CONSTRAINT [PK_TenantResources] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_TenantResources_SkuVariants_SkuVariantId] FOREIGN KEY ([SkuVariantId]) REFERENCES [SkuVariants] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_TenantResources_Tenants_TenantId] FOREIGN KEY ([TenantId]) REFERENCES [Tenants] ([Id])
);
GO

CREATE TABLE [TenantSkuVariantVersions] (
    [SkuVariantVersionId] uniqueidentifier NOT NULL,
    [TenantId] uniqueidentifier NOT NULL,
    [Status] varchar(50) NOT NULL DEFAULT 'NotStarted',
    CONSTRAINT [PK_TenantSkuVariantVersions] PRIMARY KEY ([TenantId], [SkuVariantVersionId]),
    CONSTRAINT [FK_TenantSkuVariantVersions_SkuVariantVersions_SkuVariantVersionId] FOREIGN KEY ([SkuVariantVersionId]) REFERENCES [SkuVariantVersions] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_TenantSkuVariantVersions_Tenants_TenantId] FOREIGN KEY ([TenantId]) REFERENCES [Tenants] ([Id]) ON DELETE CASCADE
);
GO

CREATE INDEX [IX_ConfigurationVersions_ConfigurationId] ON [ConfigurationVersions] ([ConfigurationId]);
GO

CREATE INDEX [IX_SkuVariants_ConfigurationVersionId] ON [SkuVariants] ([ConfigurationVersionId]);
GO

CREATE INDEX [IX_SkuVariants_SkuId] ON [SkuVariants] ([SkuId]);
GO

CREATE INDEX [IX_SkuVariantVersions_SkuVariantId] ON [SkuVariantVersions] ([SkuVariantId]);
GO

CREATE INDEX [IX_TenantResources_SkuVariantId] ON [TenantResources] ([SkuVariantId]);
GO

CREATE INDEX [IX_TenantResources_TenantId] ON [TenantResources] ([TenantId]);
GO

CREATE INDEX [IX_Tenants_ConfigurationVersionId] ON [Tenants] ([ConfigurationVersionId]);
GO

CREATE INDEX [IX_TenantSkuVariantVersions_SkuVariantVersionId] ON [TenantSkuVariantVersions] ([SkuVariantVersionId]);
GO

INSERT INTO [__TesseractEFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20220403060350_InitialCreate', N'6.0.3');
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

ALTER TABLE [SkuVariants] DROP CONSTRAINT [FK_SkuVariants_ConfigurationVersions_ConfigurationVersionId];
GO

DROP INDEX [IX_SkuVariants_ConfigurationVersionId] ON [SkuVariants];
GO

DECLARE @var0 sysname;
SELECT @var0 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[SkuVariants]') AND [c].[name] = N'ConfigurationVersionId');
IF @var0 IS NOT NULL EXEC(N'ALTER TABLE [SkuVariants] DROP CONSTRAINT [' + @var0 + '];');
ALTER TABLE [SkuVariants] DROP COLUMN [ConfigurationVersionId];
GO

CREATE TABLE [ConfigurationVersionSkuVariant] (
    [ConfigurationVersionsId] uniqueidentifier NOT NULL,
    [SkuVariantsId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_ConfigurationVersionSkuVariant] PRIMARY KEY ([ConfigurationVersionsId], [SkuVariantsId]),
    CONSTRAINT [FK_ConfigurationVersionSkuVariant_ConfigurationVersions_ConfigurationVersionsId] FOREIGN KEY ([ConfigurationVersionsId]) REFERENCES [ConfigurationVersions] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_ConfigurationVersionSkuVariant_SkuVariants_SkuVariantsId] FOREIGN KEY ([SkuVariantsId]) REFERENCES [SkuVariants] ([Id]) ON DELETE CASCADE
);
GO

CREATE INDEX [IX_ConfigurationVersionSkuVariant_SkuVariantsId] ON [ConfigurationVersionSkuVariant] ([SkuVariantsId]);
GO

INSERT INTO [__TesseractEFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20220404135907_AddJoinTables', N'6.0.3');
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

ALTER TABLE [Tenants] DROP CONSTRAINT [FK_Tenants_ConfigurationVersions_ConfigurationVersionId];
GO

DROP TABLE [ConfigurationVersionSkuVariant];
GO

DROP TABLE [TenantResources];
GO

DROP TABLE [ConfigurationVersions];
GO

DECLARE @var1 sysname;
SELECT @var1 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[SkuVariantVersions]') AND [c].[name] = N'Template');
IF @var1 IS NOT NULL EXEC(N'ALTER TABLE [SkuVariantVersions] DROP CONSTRAINT [' + @var1 + '];');
ALTER TABLE [SkuVariantVersions] DROP COLUMN [Template];
GO

EXEC sp_rename N'[Tenants].[ConfigurationVersionId]', N'ConfigurationId', N'COLUMN';
GO

EXEC sp_rename N'[Tenants].[IX_Tenants_ConfigurationVersionId]', N'IX_Tenants_ConfigurationId', N'INDEX';
GO

ALTER TABLE [SkuVariantVersions] ADD [TemplateSpecId] nvarchar(200) NOT NULL DEFAULT N'';
GO

CREATE TABLE [ConfigurationSkuVariant] (
    [ConfigurationsId] uniqueidentifier NOT NULL,
    [SkuVariantsId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_ConfigurationSkuVariant] PRIMARY KEY ([ConfigurationsId], [SkuVariantsId]),
    CONSTRAINT [FK_ConfigurationSkuVariant_Configurations_ConfigurationsId] FOREIGN KEY ([ConfigurationsId]) REFERENCES [Configurations] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_ConfigurationSkuVariant_SkuVariants_SkuVariantsId] FOREIGN KEY ([SkuVariantsId]) REFERENCES [SkuVariants] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [Resources] (
    [Id] uniqueidentifier NOT NULL,
    [TenantId] uniqueidentifier NOT NULL,
    [Type] nvarchar(max) NOT NULL,
    [Class] nvarchar(100) NOT NULL,
    [ResourceId] nvarchar(4000) NOT NULL,
    [Description] nvarchar(max) NULL,
    [ResourceGroupName] nvarchar(200) NOT NULL,
    [Status] varchar(50) NOT NULL,
    [SkuVariantId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Resources] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Resources_SkuVariants_SkuVariantId] FOREIGN KEY ([SkuVariantId]) REFERENCES [SkuVariants] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Resources_Tenants_TenantId] FOREIGN KEY ([TenantId]) REFERENCES [Tenants] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [CosmosDbDatabases] (
    [Id] uniqueidentifier NOT NULL,
    [DatabaseName] nvarchar(200) NOT NULL,
    [CosmosDbAccountName] nvarchar(200) NOT NULL,
    CONSTRAINT [PK_CosmosDbDatabases] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_CosmosDbDatabases_Resources_Id] FOREIGN KEY ([Id]) REFERENCES [Resources] ([Id])
);
GO

CREATE TABLE [KeyVaultSecrets] (
    [Id] uniqueidentifier NOT NULL,
    [KeyVaultName] nvarchar(max) NOT NULL,
    [SecretName] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_KeyVaultSecrets] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_KeyVaultSecrets_Resources_Id] FOREIGN KEY ([Id]) REFERENCES [Resources] ([Id])
);
GO

CREATE TABLE [SqlServerDatabases] (
    [Id] uniqueidentifier NOT NULL,
    [DatabaseName] nvarchar(max) NOT NULL,
    [ElasticPoolId] nvarchar(max) NULL,
    [SqlServerFullyQualifiedDomainName] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_SqlServerDatabases] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_SqlServerDatabases_Resources_Id] FOREIGN KEY ([Id]) REFERENCES [Resources] ([Id])
);
GO

CREATE INDEX [IX_ConfigurationSkuVariant_SkuVariantsId] ON [ConfigurationSkuVariant] ([SkuVariantsId]);
GO

CREATE INDEX [IX_Resources_SkuVariantId] ON [Resources] ([SkuVariantId]);
GO

CREATE INDEX [IX_Resources_TenantId] ON [Resources] ([TenantId]);
GO

ALTER TABLE [Tenants] ADD CONSTRAINT [FK_Tenants_Configurations_ConfigurationId] FOREIGN KEY ([ConfigurationId]) REFERENCES [Configurations] ([Id]) ON DELETE CASCADE;
GO

INSERT INTO [__TesseractEFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20220408054836_RemoveConfigurationVersion', N'6.0.3');
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

ALTER TABLE [Tenants] DROP CONSTRAINT [FK_Tenants_Configurations_ConfigurationId];
GO

DROP INDEX [IX_Tenants_ConfigurationId] ON [Tenants];
GO

ALTER TABLE [Tenants] ADD [CreatedAt] datetime2 NOT NULL DEFAULT '0001-01-01T00:00:00.0000000';
GO

ALTER TABLE [SkuVariantVersions] ADD [CreatedAt] datetime2 NOT NULL DEFAULT '0001-01-01T00:00:00.0000000';
GO

ALTER TABLE [SkuVariantVersions] ADD [CreatedUserId] uniqueidentifier NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
GO

ALTER TABLE [SkuVariants] ADD [CreatedAt] datetime2 NOT NULL DEFAULT '0001-01-01T00:00:00.0000000';
GO

ALTER TABLE [SkuVariants] ADD [CreatedUserId] uniqueidentifier NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
GO

ALTER TABLE [Skus] ADD [CreatedAt] datetime2 NOT NULL DEFAULT '0001-01-01T00:00:00.0000000';
GO

ALTER TABLE [Skus] ADD [CreatedUserId] uniqueidentifier NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
GO

ALTER TABLE [Configurations] ADD [CreatedAt] datetime2 NOT NULL DEFAULT '0001-01-01T00:00:00.0000000';
GO

ALTER TABLE [Configurations] ADD [CreatedUserId] uniqueidentifier NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
GO

INSERT INTO [__TesseractEFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20220416074827_AddBaseEntityColumns', N'6.0.3');
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

DECLARE @var2 sysname;
SELECT @var2 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Tenants]') AND [c].[name] = N'CreatedAt');
IF @var2 IS NOT NULL EXEC(N'ALTER TABLE [Tenants] DROP CONSTRAINT [' + @var2 + '];');
ALTER TABLE [Tenants] ALTER COLUMN [CreatedAt] datetimeoffset NOT NULL;
GO

DECLARE @var3 sysname;
SELECT @var3 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[SkuVariantVersions]') AND [c].[name] = N'CreatedAt');
IF @var3 IS NOT NULL EXEC(N'ALTER TABLE [SkuVariantVersions] DROP CONSTRAINT [' + @var3 + '];');
ALTER TABLE [SkuVariantVersions] ALTER COLUMN [CreatedAt] datetimeoffset NOT NULL;
GO

DECLARE @var4 sysname;
SELECT @var4 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[SkuVariants]') AND [c].[name] = N'CreatedAt');
IF @var4 IS NOT NULL EXEC(N'ALTER TABLE [SkuVariants] DROP CONSTRAINT [' + @var4 + '];');
ALTER TABLE [SkuVariants] ALTER COLUMN [CreatedAt] datetimeoffset NOT NULL;
GO

DECLARE @var5 sysname;
SELECT @var5 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Skus]') AND [c].[name] = N'CreatedAt');
IF @var5 IS NOT NULL EXEC(N'ALTER TABLE [Skus] DROP CONSTRAINT [' + @var5 + '];');
ALTER TABLE [Skus] ALTER COLUMN [CreatedAt] datetimeoffset NOT NULL;
GO

DECLARE @var6 sysname;
SELECT @var6 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Configurations]') AND [c].[name] = N'CreatedAt');
IF @var6 IS NOT NULL EXEC(N'ALTER TABLE [Configurations] DROP CONSTRAINT [' + @var6 + '];');
ALTER TABLE [Configurations] ALTER COLUMN [CreatedAt] datetimeoffset NOT NULL;
GO

INSERT INTO [__TesseractEFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20220417074408_UseDateTimeOffset', N'6.0.3');
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

CREATE INDEX [IX_Tenants_ConfigurationId] ON [Tenants] ([ConfigurationId]);
GO

ALTER TABLE [Tenants] ADD CONSTRAINT [FK_Tenants_Configurations_ConfigurationId] FOREIGN KEY ([ConfigurationId]) REFERENCES [Configurations] ([Id]) ON DELETE NO ACTION;
GO

INSERT INTO [__TesseractEFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20220417121012_AddFKTenantConfiguration', N'6.0.3');
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

ALTER TABLE [Tenants] DROP CONSTRAINT [FK_Tenants_Configurations_ConfigurationId];
GO

DROP INDEX [IX_Tenants_ConfigurationId] ON [Tenants];
GO

DECLARE @var7 sysname;
SELECT @var7 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Tenants]') AND [c].[name] = N'ConfigurationId');
IF @var7 IS NOT NULL EXEC(N'ALTER TABLE [Tenants] DROP CONSTRAINT [' + @var7 + '];');
ALTER TABLE [Tenants] DROP COLUMN [ConfigurationId];
GO

INSERT INTO [__TesseractEFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20220418210712_RemoveTenantConfigurationFK', N'6.0.3');
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

ALTER TABLE [TenantSkuVariantVersions] ADD [ProvisioningFailReason] nvarchar(4000) NULL;
GO

INSERT INTO [__TesseractEFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20220420190617_AddTenantSkuVariantVersionFailReason', N'6.0.3');
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

ALTER TABLE [Resources] DROP CONSTRAINT [FK_Resources_SkuVariants_SkuVariantId];
GO

ALTER TABLE [TenantSkuVariantVersions] DROP CONSTRAINT [FK_TenantSkuVariantVersions_SkuVariantVersions_SkuVariantVersionId];
GO

ALTER TABLE [Resources] ADD CONSTRAINT [FK_Resources_SkuVariants_SkuVariantId] FOREIGN KEY ([SkuVariantId]) REFERENCES [SkuVariants] ([Id]) ON DELETE NO ACTION;
GO

ALTER TABLE [TenantSkuVariantVersions] ADD CONSTRAINT [FK_TenantSkuVariantVersions_SkuVariantVersions_SkuVariantVersionId] FOREIGN KEY ([SkuVariantVersionId]) REFERENCES [SkuVariantVersions] ([Id]) ON DELETE NO ACTION;
GO

INSERT INTO [__TesseractEFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20220422052007_ResourceSkuVariantVersionRelationship', N'6.0.3');
GO

COMMIT;
GO

-- END SCRIPT

"

Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Username $username -Password $password -Query $query -QueryTimeout 36000 -Verbose

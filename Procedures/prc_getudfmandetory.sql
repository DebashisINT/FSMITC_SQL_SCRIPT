IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_getudfmandetory]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_getudfmandetory] AS' 
END
GO
 
 ALTER procedure [dbo].[prc_getudfmandetory]
 @appliFor varchar(10)=null
 as
 begin
    select h.id from dbo.tbl_master_remarksCategory h left outer join 
    tbl_master_udfGroup d on h.cat_group_id=d.id where cat_applicablefor =@appliFor
    and (grp_isVisible=1 or grp_isVisible is null) and isMandatory=1
end

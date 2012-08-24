database = require('mysql-simple');
conf = require('./conf')

database.init(
  conf.database.username, 
  conf.database.password, 
  conf.database.database, 
  conf.database.host,
  conf.database.port)

save = (json) -> 
  db.save(json, (err, res) -> {})

get_identifier_map = (type,id,callback) ->
  database.querySingle(
    """
    SELECT * FROM identifiermap im

    INNER JOIN urimap um ON 
      (
        im.resourcetype = um.resourcetype
        AND
        im.resourcename = um.resourcename
      )

    WHERE 
      im.resourcetype = ?
      AND
      im.identifier = ?
    """, [type, id],
    (err, result) ->
      callback(result)
  )


get_uri_description = (type,uri,callback) ->
  database.querySingle(
    """
    SELECT * 
    
    FROM 
      identifiermap im

    INNER JOIN urimap um ON 
      (
        im.resourcetype = um.resourcetype
        AND
        im.identifier = um.resourcename

    WHERE 
      im.resourcetype = ?
      im.identifier = ?
    """, [type, id],
    (err, result) ->
      callback(result)
  )

get_all_ids = (type,resource_name,callback) ->
  database.query(
    """
    SELECT 
      *
    
    FROM 
      identifiermap im

    INNER JOIN 
      urimap um 
    ON 
      (
        im.resourcetype = um.resourcetype
        AND
        im.resourcename = um.resourcename
      )
   
    WHERE 
      im.resourcetype = ?
      AND
      im.resourcename = ?
    """, [type, resource_name],
    (err, result) ->
      callback(result)
  )

get_version_info = (type,name,version_id,callback) ->
  database.querySingle(    
    """
    SELECT 
      *
    
    FROM 
      versionmap vm
   
    WHERE 
      vm.resourcetype = ?
      AND
      vm.resourcename = ?
      AND
      vm.versionid = ?
    """, [type,name,version_id],
    (err, result) ->
      callback(result)
  )

module.exports.save = save
module.exports.get_identifier_map = get_identifier_map
module.exports.get_uri_description = get_uri_description
module.exports.get_version_info = get_version_info
module.exports.get_all_ids = get_all_ids

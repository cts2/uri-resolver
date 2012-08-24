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

get_by_identifier = (type,identifier,callback) ->
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
      im.resourcename = ?
    """, [type, identifier],
    (err, result) ->
      callback(result)
  )

get_by_id = (type,id,callback) ->
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

get_all_ids = (type,identifier,callback) ->
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
    """, [type, identifier],
    (err, result) ->
      callback(result)
  )

get_by_version_identifier = (type,identifier,callback) ->
  database.querySingle(    
    """
    SELECT 
      *
    
    FROM 
      versionmap vm
   
    WHERE 
      vm.resourcetype = ?
      AND
      vm.versionname = ?
    """, [type,identifier],
    (err, result) ->
      callback(result)
  )

get_by_version_id = (type,identifier,version_id,callback) ->
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
    """, [type,identifier,version_id],
    (err, result) ->
      callback(result)
  )

get_all_version_ids = (type,identifier,callback) ->
  database.query(    
    """
    SELECT 
      *
    
    FROM 
      versionmap vm
   
    WHERE 
      vm.resourcetype = ?
      AND
      vm.versionname = ?
    """, [type,identifier],
    (err, result) ->
      callback(result)
  )

module.exports.save = save
module.exports.get_by_id = get_by_id
module.exports.get_by_identifier = get_by_identifier
module.exports.get_by_version_id = get_by_version_id
module.exports.get_all_ids = get_all_ids
module.exports.get_all_version_ids = get_all_version_ids
module.exports.get_by_version_identifier = get_by_version_identifier

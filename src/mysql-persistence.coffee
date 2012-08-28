database = require('mysql-simple');
conf = require('./conf')

database.init(
  conf.database.username, 
  conf.database.password, 
  conf.database.database, 
  conf.database.host,
  conf.database.port)

save_ids = (json,callback) ->
  database.nonQuery("""
    INSERT INTO urimap 
      (resourcetype, resourcename, resourceuri, baseentityuri) 
    VALUES (?, ?, ?, ?);
    """, [json.resourceType, json.resourceName, json.resourceURI, json.baseEntityURI], 
    (err, info) ->
      if(!err)
        _insert_identifier {id: identifier,type: json.resourceType,name: json.resourceName } for identifier in json.identifiers
      else
        callback(err)
  )

_insert_identifier = (json,callback) ->
  database.nonQuery("""
    INSERT INTO identifiermap 
      (resourcetype, resourcename, identifier) 
    VALUES (?, ?, ?);
    """, [json.type, json.name, json.id], callback)

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

#TODO: not sure how queries will work
query_urimaps = (q,callback) ->
  where_clause = 
        """
        WHERE 
          im.resourcetype LIKE ?
          OR
          im.resourcename LIKE ?
          OR
          im.identifier LIKE ?
          OR
          um.resourceuri LIKE ?
        """
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
   
    #{
      (() ->
        if(q)
          return where_clause
        else
          return ""
      )()
    }
    """, 
    if(q)
      q = "%#{q}%"
      [q,q,q,q]
    else 
      []
    ,
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

module.exports.save_ids = save_ids
module.exports.get_by_id = get_by_id
module.exports.get_by_identifier = get_by_identifier
module.exports.get_by_version_id = get_by_version_id
module.exports.get_all_ids = get_all_ids
module.exports.get_all_version_ids = get_all_version_ids
module.exports.get_by_version_identifier = get_by_version_identifier
module.exports.query_urimaps = query_urimaps

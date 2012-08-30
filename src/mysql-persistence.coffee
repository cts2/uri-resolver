database = require('./db')
queues = require('mysql-queues')
conf = require('./conf')

database.init(
  conf.database.username, 
  conf.database.password, 
  conf.database.database, 
  conf.database.host,
  conf.database.port)

save_ids = (json,callback) ->
  database.doWithClient(
    (client) ->
      _save_ids(client,json,callback)
  )

_save_ids = (client,json,callback) ->
  trans = client.startTransaction();

  error = (err,id) ->
    if(err && !trans.rolledback && trans.rollback)
      console.log("Rolling back...")
      if(id)
        callback("Error inserting ID: " + id + ". This ID is already in use.")
      else
        callback(err)
      trans.rollback()

  trans.query("""
    DELETE FROM 
      urimap
    WHERE resourcename = ?
    """, [json.resourceName],error)

  trans.query("""
    INSERT INTO urimap 
      (resourcetype, resourcename, resourceuri, baseentityuri) 
    VALUES (?, ?, ?, ?)
    """, [json.resourceType, json.resourceName, json.resourceURI, json.baseEntityURI],error)

  for id in json.identifiers
    trans.query("""
      INSERT INTO identifiermap 
        (resourcetype, resourcename, identifier) 
      VALUES (?,?,?)
      """, [json.resourceType, json.resourceName, id], (err) -> error(err,id))

  trans.commit(
    (err, info) ->
      callback(err)
  )

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

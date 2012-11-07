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

save_version_ids = (json,callback) ->
  database.doWithClient(
    (client) ->
      _save_version_ids(client,json,callback)
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
      client.end()

  if(json.oldResourceName)
    trans.query("""
      DELETE FROM 
        urimap
      WHERE resourcetype = ? AND resourcename = ?
      """, [json.resourceType, json.oldResourceName],error)

  trans.query("""
    DELETE FROM 
      urimap
    WHERE resourcetype = ? AND resourcename = ?
    """, [json.resourceType, json.resourceName],error)

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
      client.end()
      callback(err)
  )

_save_version_ids = (client,json,callback) ->
  trans = client.startTransaction();

  error = (err,id) ->
    if(err && !trans.rolledback && trans.rollback)
      console.log("Rolling back...")
      if(id)
        callback("Error inserting ID: " + id + ". This ID is already in use.")
      else
        callback(err)

      trans.rollback()
      client.end()

  trans.query("""
    DELETE FROM 
      urimap
    WHERE resourcetype = ? AND resourcename = ?
    """, [json.resourceType, json.resourceName],error)

  trans.query("""
    INSERT INTO urimap 
      (resourcetype, resourcename, resourceuri) 
    VALUES (?, ?, ?)
    """, [json.resourceType, json.resourceName, json.resourceURI],error)

  for id in json.identifiers
    trans.query("""
      INSERT INTO versionmap 
        (resourcetype, resourcename, versionid, versionname, versiontype) 
      VALUES (?,?,?,?,?)
      """, [_version_type_to_type(json.resourceType), json.versionOf, id, json.resourceName, json.resourceType], (err) -> error(err,id))

  trans.commit(
    (err, info) ->
      client.end()
      callback(err)
  )

get_by_identifier = (type,identifier,callback) ->
  database.querySingle(
    """
    SELECT * FROM urimap um

    WHERE 
      um.resourcetype = ?
      AND
      um.resourcename = ?

    """, [type, identifier],
    (err, result) ->
      callback(result)
  )

get_by_id = (type,id,callback) ->
  database.querySingle(
    """
    SELECT 
      um.resourcetype ResourceType,
      um.resourcename ResourceName,
      um.resourceuri ResourceURI,
      um.baseentityuri BaseEntityURI,
      im.identifier

    FROM urimap um

    LEFT JOIN identifiermap im ON 
      (
        im.resourcetype = um.resourcetype
        AND
        im.resourcename = um.resourcename
      )

    WHERE 
      um.resourcetype = ?
      AND
      (
        um.resourcename = ?
        OR
        im.identifier = ?
      )

    """, [type, id, id],
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
      um.resourcetype ResourceType,
      um.resourcename ResourceName,
      um.resourceuri ResourceURI,
      um.baseentityuri BaseEntityURI,
      im.identifier

    FROM 
      identifiermap im

    LEFT JOIN 
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
      um.resourcetype ResourceType,
      um.resourcename ResourceName,
      um.resourceuri ResourceURI,
      um.baseentityuri BaseEntityURI,
      im.identifier Identifier
    
    FROM 
      urimap um 

    LEFT JOIN 
      identifiermap im
      
    ON 
      (
        im.resourcetype = um.resourcetype
        AND
        im.resourcename = um.resourcename
      )
   
    WHERE 
      um.resourcetype = ?
      AND
      um.resourcename = ?
    """, [type, identifier],
    (err, result) ->
      callback(result)
  )

get_by_version_id = (type,identifier,version_id,callback) ->
  database.querySingle(    
    """
    SELECT 
      *
    FROM 
      urimap um 
      
    INNER JOIN
      versionmap vm
    ON
    (
      um.resourcetype = vm.resourcetype
      AND
      um.resourcename = vm.resourcename
    )
    WHERE 
      vm.resourcetype = ?
      AND
      vm.resourcename = ?
      AND
      (
        vm.versionid = ?
        OR
        vm.resourcename = ?
      )
    """, [type,identifier,version_id,version_id],
    (err, result) ->
      callback(result)
  )

_type_to_version_type = (type) ->
  switch type
    when "CODE_SYSTEM" then "CODE_SYSTEM_VERSION"
    when "MAP" then "MAP_VERSION"

_version_type_to_type = (type) ->
  switch type
    when "CODE_SYSTEM_VERSION" then "CODE_SYSTEM"
    when "MAP_VERSION" then "MAP"

get_all_version_ids = (type,identifier,callback) ->
  database.query(    
    """
    SELECT 
      um.resourcetype as ResourceType,
      um.resourcename as ResourceName,
      um.resourceuri as VersionURI,
      vm.versionname as VersionName,
      vm.resourcename as VersionOfName,
      vm.versionid as VersionId
    FROM 
      urimap um 
      
    LEFT JOIN
      versionmap vm
    ON
    (
      um.resourcetype = vm.versiontype
      AND
      um.resourcename = vm.versionname
    )
    WHERE 
      um.resourcetype = ?
      AND
      um.resourcename = ?
    """, [type,identifier],
    (err, result) ->
      callback(result)
  )

module.exports.save_ids = save_ids
module.exports.save_version_ids = save_version_ids
module.exports.get_by_id = get_by_id
module.exports.get_by_identifier = get_by_identifier
module.exports.get_by_version_id = get_by_version_id
module.exports.get_all_ids = get_all_ids
module.exports.get_all_version_ids = get_all_version_ids
module.exports.query_urimaps = query_urimaps

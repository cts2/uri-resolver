restify = require 'restify'
persistence = require './mysql-persistence'
config = require './conf'
fs = require 'fs'

server = restify.createServer({
  formatters : {
    'text/html': (req, res, body) -> return body
    'text/css': (req, res, body) -> return body
  }
})

server.use(restify.queryParser())
server.use(restify.bodyParser({ mapParams: false }))
server.use(restify.authorizationParser())

#TODO: not sure how queries will work
query_urimaps = (req, res, next) ->
  query = req.query.q

  build_query_result = (row) ->
    return_result =
      resourceName : row.ResourceName
    return_result

  persistence.query_urimaps(query, 
    (results) -> 
      if(results and results[0])
        query_result = (build_query_result result for result in results)
        res.send(query_result)
      else
        res.send( {} )
  )

get_namespace_by_id = (req, res, next) ->
  id = req.query.id
  persistence.get_by_id("CODE_SYSTEM",id, 
    (result) -> 
      if(result)
        res.header('Location', "/namespace/#{result.ResourceName}");
        res.send(302)
      else
        send_error(404, "Resource Not Found", res)
  )

get_namespace_by_identifier = (req, res, next) ->
  identifier = req.params.identifier
  persistence.get_by_identifier("CODE_SYSTEM",identifier, 
    (result) -> 
      if(result)
        return_type =
          prefix : result.ResourceName
          namespaceURI : result.ResourceURI

        res.send(return_type)
      else
        send_error(404, "Resource Not Found", res)
  )

save_ids = (req, res, next) ->
  type = req.params.type
  identifier = req.params.identifier

  persistence.save_ids(req.body,
    (err,info) ->
      if(err)
        send_error(500,err,res)
      else
        res.send({message:"saved"})
  )

get_by_identifier = (req, res, next) ->
  type = req.params.type
  identifier = req.params.identifier
  persistence.get_by_identifier(type,identifier, 
    (result) -> 
      if(result)
        resource_type = result.ResourceType
        return_type =
          resourceType : resource_type
          resourceName : result.ResourceName
          resourceURI : result.ResourceURI
          baseEntityURI : if resource_type == "CODE_SYSTEM" then result.BaseEntityURI else null

        res.send(return_type)
      else
        send_error(404, "Resource Not Found", res)
  )

get_by_id = (req, res, next) ->
  type = req.params.type
  id = req.query.id
  persistence.get_by_id(type,id, 
    (result) -> 
      if(result)
        res.header('Location', "/id/#{result.ResourceType}/#{result.ResourceName}");
        res.send(302)
      else
        send_error(404, "Resource Not Found", res)
  )

get_all_version_ids = (req, res, next) ->
  type = req.params.type
  identifier = req.params.identifier
  persistence.get_all_version_ids("CODE_SYSTEM",identifier
    (result) -> 
      if(result and result[0])
        return_type =
          resourceURI : result[0].VersionURI
          resourceName : result[0].VersionName
          identifiers : (row.VersionId for row in result)
        res.send(return_type)
      else
        send_error(404, "Resource Not Found", res)
  )

get_by_version_id = (req, res, next) ->
  type = req.params.type
  identifier = req.params.identifier
  version_id = req.params.version_id
  persistence.get_by_version_id(type,identifier,version_id,
    (result) -> 
      if(result)
        if(result.VersionName == result.VersionId)
          return_type =
            resourceURI : result.VersionURI
            resourceName : result.VersionName
          res.send(return_type)
        else
          res.header('Location', "/version/CODE_SYSTEM_VERSION/#{result.VersionName}");
          res.send(302)
      else
        send_error(404, "Resource Not Found", res)
  )

get_by_version_identifier = (req, res, next) ->
  type = req.params.type
  identifier = req.params.identifier
  persistence.get_by_version_identifier("CODE_SYSTEM",identifier
    (result) -> 
      if(result)
          return_type =
            resourceURI : result.VersionURI
            resourceName : result.VersionName
          res.send(return_type)
      else
        send_error(404, "Resource Not Found", res)
  )

get_all_ids = (req, res, next) ->
  type = req.params.type
  identifier = req.params.identifier
  persistence.get_all_ids(type,identifier, 
    (result) -> 
      if(result and result[0])
        return_type =
          resourceType : result[0].ResourceType
          resourceName : result[0].ResourceName
          resourceURI : result[0].ResourceURI
          identifiers : (row.Identifier for row in result)
        res.send(return_type)
      else
        send_error(404, "Resource Not Found", res)
  )

send_error = (code, message, res) ->
  res.send(code, {'error_message' : message})

authenticate = (req, res, next) ->
  authz = req.authorization
  err = null

  if (!authz || authz.scheme != 'Basic' || authz.basic.username != config.server.admin_username || authz.basic.password != config.server.admin_password)
      res.header('WWW-Authenticate', 'Basic realm="Please login"');
      res.send(401);
      err = false;

  next(err);

send_static = (file, type) ->
  (req, res, next) ->
    fs.readFile(file, 'utf8', 
      (err, file) ->
        if(err) 
          res.send(500)
          return next()

        res.contentType = type
        res.header('Content-Type',type)
        res.send(file)
    )

start_server = () ->
  server.get('/admin', send_static('../index.html', 'text/html') )
  server.get('/style.css', send_static('../style.css', 'text/css') )
  server.get('/id/:type', get_by_id )
  server.get('/id/:type/:identifier', get_by_identifier )
  server.get('/ids/:type/:identifier', get_all_ids )
  server.put('/ids/:type/:identifier', authenticate, save_ids )

  #TODO: not sure how queries will work
  server.get('/urimaps', query_urimaps )

  server.get('/version/:type/:identifier/:version_id', get_by_version_id )
  server.get('/version/:type/:identifier', get_by_version_identifier )
  server.get('/versions/:type/:identifier', get_all_version_ids )
  server.get('/namespace', get_namespace_by_id )
  server.get('/namespace/:identifier', get_namespace_by_identifier )

  server.listen(config.server.port, () ->
    console.log('%s listening at %s', server.name, server.url) )
    
build_identifier_map = (row) ->
  identifier_map =
    identifierType : row.ResourceType
    identifier : row.Identifier
    uri : uri

start_server()

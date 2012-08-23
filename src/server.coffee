restify = require 'restify'
persistence = require './mysql-persistence'

server = restify.createServer()

server.use(restify.queryParser())
server.use(restify.bodyParser({ mapParams: false }))

save = (req, res, next) ->
  persistence.save(req.body)
  res.send(201)

get_by_identifier = (req, res, next) ->
  type = req.params.type
  id = req.params.local_identifier
  persistence.get_identifier_map(type,id, 
    (result) -> 
      if(result)
        res.send(result)
      else
        send_error(404, "Resource Not Found", res)
  )

get_by_id = (req, res, next) ->
  type = req.params.type
  id = req.query.id
  persistence.get_identifier_map(type,id, 
    (result) -> 
      if(result)
        res.header('Location', "/uri/#{result.ResourceType}/#{result.ResourceName}");
        res.send(302)
      else
        send_error(404, "Resource Not Found", res)
  )

get_all_ids = (req, res, next) ->
  type = req.params.type
  id = req.params.local_identifier
  persistence.get_all_ids(type,id, 
    (result) -> 
      if(result)
        return_type =
          localIdentifier : result[0].ResourceName
          uri : result[0].ResourceURI
          identifiers : (build_identifier(row) for row in result)
        res.send(return_type)
      else
        send_error(404, "Resource Not Found", res)
  )

build_identifier = (row) ->
  identifier = 
    identifier : row.Identifier
    source : row.Source
    sourceVersion : row.SourceVersion

  identifier

send_error = (code, message, res) ->
  res.send(code, {'error_message' : message})

start_server = () ->
  server.get('/id/:type', get_by_id )
  server.get('/uri/:type/:local_identifier', get_by_identifier )
  server.get('/ids/:type/:local_identifier', get_all_ids )
  server.post('/ids', save )

  server.listen(8080, () ->
    console.log('%s listening at %s', server.name, server.url) )
    
build_identifier_map = (row) ->
  identifier_map =
    identifierType : row.ResourceType
    identifier : row.Identifier
    uri : uri

start_server()

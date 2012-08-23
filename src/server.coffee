restify = require 'restify'
persistence = require './mysql-persistence'

server = restify.createServer()

server.use(restify.queryParser())
server.use(restify.bodyParser({ mapParams: false }))

save = (req, res, next) ->
  persistence.save(req.body)
  res.send(201)

get_by_id = (req, res, next) ->
  type = req.params.type
  id = req.query.id
  persistence.get_identifier_map(type,id, (result) -> process_return(result,res))
 
process_return = (result,res) ->
  if(result)
    res.send(result)
  else
    res.send(404, {'error_message' : "Resource Not Found"})

start_server = () ->
  server.get('/id/:type', get_by_id )
  server.post('/ids', save )

  server.listen(8080, () ->
    console.log('%s listening at %s', server.name, server.url) )
    
build_identifier_map = (type,uri,id) ->
  identifier_map =
    identifierType : type
    identifier : id
    uri : uri

start_server()

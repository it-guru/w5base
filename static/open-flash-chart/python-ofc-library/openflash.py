import random
from mod_python import apache, util
from OpenFlashChart import *

def handler(req):
  req.content_type = 'text/html'

  req.write( "<html><body>" )

  params = util.FieldStorage(req)
  uri = "http://%s%s" % (req.hostname, req.uri)
  data_uri = "%s?cmd=data" % uri
  if params.get("cmd", None) == 'data':
    g = graph()

    data_1 = []
    data_2 = []
    data_3 = []
    for i in range(12):
      data_1.append( random.randint(14,19) )
      data_2.append( random.randint(8,13) )
      data_3.append( random.randint(1,7) )

    g.title( 'Many data lines' )

    # we add 3 sets of data:
    g.set_data( data_1 )
    g.set_data( data_2 )
    g.set_data( data_3 )

    # we add the 3 line types and key labels
    g.line( 2, '0x9933CC', 'Page views', 10 )
    g.line_dot( 3, 5, '0xCC3399', 'Downloads', 10)    # <-- 3px thick + dots
    g.line_hollow( 2, 4, '0x80a033', 'Bounces', 10 )

    g.set_x_labels( 'January,February,March,April,May,June,July,August,Spetember,October,November,December'.split(',') )
    g.set_x_label_style( 10, '0x000000', 0, 2 )

    g.set_y_max( 20 )
    g.y_label_steps( 4 )
    g.set_y_legend( 'Open Flash Chart Python', 12, '0x736AFF' )
    req.write( g.render() )

    req.write( "<body><html>" )
  else:
    obj = graph_object()
    req.write( obj.render( 200, 200, data_uri ) )
  return apache.OK


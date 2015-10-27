(function(global, d3) {
  'use strict';

  var graph = {};

  // Gráfico de bolhas
  graph.Bubble = function(options) {
    // Define valores padrão para argumentos
    var context = options.context || 'body'
      , diameter = options.size || 960;

    // Define formatação e escala de cores
    var format = d3.format('.d'),
        color = d3.scale.category20c();

    // Define o layout do gráfico
    var bubble = d3.layout.pack()
      .sort(null)
      .size([diameter, diameter])
      .padding(1.5);

    // Cria o svg e insere na página
    var svg = d3.select(context)
      .append('div')
        .attr('class', 'graph')
      .append('div')
        .attr('class', 'bubble_chart')
      .append('svg')
        .attr('width', diameter)
        .attr('height', diameter);

    // Cria e insere os nodos
    var node = svg.selectAll('.node')
      .data(bubble.nodes(classes(options.data))
      .filter(function(d) {
        return !d.children;
      }))
      .enter()
      .append('g')
        .attr('class', 'node')
        .attr('transform', function(d) {
          return 'translate(' + d.x + ',' + d.y + ')';
        });

    // Isere um titulo para cada nodo
    node.append('title')
      .text(function(d) {
        return d.className + ': ' + format(d.value);
      });

    // Insere as bolhas (circulos) para cada nodo
    node.append('circle')
      .attr('class', 'circle')
      .attr('r', function(d) {
        return d.r;
      })
      .style('fill', function(d) {
        return color(d.packageName);
      });

    // Insere o texto (descrição) para cada nodo
    node.append('text')
      .attr('dy', '.3em')
      .style('text-anchor', 'middle')
      .text(function(d) {
        return d.className.substring(0, d.r / 3);
      });

    // Retorna uma hierarquia achatada contendo todos os nodos de folha na raiz.
    function classes(root) {
      var classes = [];

      function recurse(name, node) {
        if (node.children) {
          node.children.forEach(function(child) {
            recurse(node.name, child);
          });
        } else {
          classes.push({
            packageName: name, className: node.name, value: node.size
          });
        }
      }

      recurse(null, root);
      return {children: classes};
    }
  };

  // Gráfico de barras
  graph.Bar = function(options) {
    // Define valores padrão para argumentos
    var context  = options.context || 'body'
      , width = options.size || 900
      , height;

    // Define largura das barras    
    var barHeight = 15;

    // Define as margens
    var margin = {top: 20, right: 20, bottom: 20, left: 0};
    
    for (var i = 0; i < options.data.length; i++) {
      var d = options.data[i].name.split(' ');
      var v = d[0].length + d[d.length - 1].length + 1;
      if (v > margin.left) {
        margin.left = v;
      }
    }
    
    margin.left *= 5.5;
    margin.left += 20;
    
    // Filtro para remover objetos com valor 0
    options.data = options.data.filter(function(item) {
      return (item.size > 0);
    });

    // Ajusta o tamanho
    width -= margin.left + margin.right;
    height = options.data.length * barHeight;

    // Define a escala para x e y
    var x = d3.scale.linear()
      .range([0, width]);

    var y = d3.scale.ordinal()
      .rangeRoundBands([0, height], .1);

    // Define o dominio para x e y
    x.domain([0, d3.max(options.data, function(d) {
      return d.size;
    })]);

    y.domain(options.data.map(function(d) {
      return d.name;
    }));

    // Define os eixos x e y
    var xAxis = d3.svg.axis()
      .scale(x)
      .orient('top');

    var yAxis = d3.svg.axis()
      .scale(y)
      .tickSize(5, 0)
      .orient('left');

    // Cria o svg e insere na página
    var svg = d3.select(context)
      .append('div')
        .attr('class', 'graph')
      .append('div')
        .attr('class', 'bar_chart')
      .append('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
      .append('g')
        .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')');

    // Insere os eixos
    svg.append('g')
      .attr('class', 'x axis')
      .call(xAxis);

    svg.append('g')
      .attr('class', 'y axis')
      .attr('transform', 'translate(-10, 0)')
      .call(yAxis)
      .selectAll('text')
      .data(options.data)
      .text(function(d) {
        var name = d.name.split(' ');
        return (name[0] + ' ' + name[name.length-1])
                .replace(/(?:^|\s)\S/g, function(a) {
                  return a.toUpperCase();
                });
      })
      .attr('dy', '.35em')
      .style('text-anchor', 'left')
      .append('title')
        .text(function(d) {
          return d.name.replace(/(?:^|\s)\S/g, function(a) {
            return a.toUpperCase();
          });
        });

    // Insere as barras  
    svg.selectAll('.bar')
      .data(options.data)
      .enter()
      .append('rect')
        .attr('class', 'bar')
        .attr('y', function(d) {
          return y(d.name);
        })
        .attr('width', function(d) {
          return  x(d.size);
        })
        .attr('height', barHeight - 2)
      .append('title')
        .text(function(d) {
          return (d.name.replace(/(?:^|\s)\S/g, function(a) {
            return a.toUpperCase();
          })) + ': ' + d.size;
        });
  };

  if (global) {
    global.graph = graph;
  }
})(this, this.d3);
(function(global, d3) {
  'use strict';

  /**
   * =========================================================================
   * Public functions
   * =========================================================================
   */

  /**
   * Graph constructor
   */

  var Graph = function(options) {
    if (!options) {
      return this; 
    }
    return this.setProperty(options);
  };

  /**
   * Bubble graphic
   */

  Graph.prototype.bubble = function() {
    // Arguments
    if (!this.argExists(['context', 'data', 'size'])) {
      return null;
    }

    // Define formatação e escala de cores
    var format = d3.format('.d')
      , color = d3.scale.category20c();

    // Define o layout do gráfico
    var bubble = d3.layout.pack()
      .sort(null)
      .size([this.size, this.size])
      .padding(1.5);

    // Cria o svg e insere na página
    var svg = d3.select(this.context).html('')
      .append('div')
        .attr('class', 'graph')
      .append('div')
        .attr('class', 'bubble_chart')
      .append('svg')
        .attr('width', this.size)
        .attr('height', this.size);

    // Cria e insere os nodos
    var node = svg.selectAll('.node')
      .data(bubble.nodes(this.data)
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

    return this;
  };

  /**
   * Bar graphic
   */

  Graph.prototype.bar = function() {
    // Arguments
    if (!this.argExists(['context', 'data', 'size'])) {
      return null;
    }

    // Define valores padrão para argumentos
    var width = this.size
      , height;

    // Define largura das barras    
    var barHeight = 15;

    // Define as margens
    var margin = {top: 20, right: 20, bottom: 20, left: 0};
    
    for (var i = 0; i < this.data.length; i++) {
      var d = this.data[i].name.split(' ');
      var v = d[0].length + d[d.length - 1].length + 1;
      if (v > margin.left) {
        margin.left = v;
      }
    }
    
    margin.left *= 5.5;
    margin.left += 20;

    // Ajusta o tamanho
    width -= margin.left + margin.right;
    height = this.data.length * barHeight;

    // Define a escala para x e y
    var x = d3.scale.linear()
      .range([0, width]);

    var y = d3.scale.ordinal()
      .rangeRoundBands([0, height], .1);

    // Define o dominio para x e y
    x.domain([0, d3.max(this.data, function(d) {
      return d.size;
    })]);

    y.domain(this.data.map(function(d) {
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
    var svg = d3.select(this.context).html('')
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
      .data(this.data)
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
      .data(this.data)
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

    return this;
  };

  /**
   * Set all properties of options in Graph
   */

  Graph.prototype.setProperty = function(options) {
    Object.keys(options).forEach(function(key) {
      this[key] = options[key];
    }, this);
    return this;
  };

  /**
   * Check if has properties
   */

  Graph.prototype.argExists = function(args) {
    for (var i = 0; i < args.length; i++) {
      if (!this.hasOwnProperty(args[i])) {
        return false;
      }
    }    
    return true;    
  };

  /**
   * =========================================================================
   * Exports
   * =========================================================================
   */

  if (global) {
    global.Graph = Graph;
  }

})(this, this.d3);
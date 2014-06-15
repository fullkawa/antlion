require 'cairo'
require 'matrix'

include Math

class Board
  # ボード A4横
  # 単位はポイント @see http://rcairo.github.io/doc/ja/cairo-svg-surface.html#label-3
  WIDTH = 841
  HEIGHT = 595

  CX = WIDTH / 2
  CY = HEIGHT / 2

  THICK = 8
end

class Field
  # 中心円の半径
  CENTER_R = 28
  # 外周の半径
  OUTER_R = 288

  ROUTE_WIDTH = 56

  # マス
  SW = Board::THICK + 4
  SH = Board::THICK + 4

  CX = Board::CX
  CY = Board::CY

  def draw_field(context)
    context.arc(0, 0, CENTER_R, 0, 2*PI)
    context.stroke

    context.arc(0, 0, OUTER_R, 0, 2*PI)
    context.stroke
  end

  def draw_border(context)
    # context.move_to(CX, CY)
    0.step(-1545, -1) { |deg|
      rad = deg * PI / 180
      ba = (deg.to_f / 360).abs * ROUTE_WIDTH + CENTER_R
      bx = ba * cos(rad)
      by = ba * sin(rad)
      context.line_to(bx, by)
    }
    context.stroke
  end

  def draw_step(context)
    deg = -250
    @steps = Array.new
    for i in 0..71
      rad = deg * PI / 180
      sa = (deg.to_f / 360).abs * Field::ROUTE_WIDTH + Field::CENTER_R - Field::ROUTE_WIDTH * 0.5
      sx = sa * cos(rad)
      sy = sa * sin(rad)
      @steps << {:x => sx, :y => sy}

      x1, y1 = rotate( 1*SW/2,  1*SH/2, sx, sy, rad)
      context.move_to(x1, y1)
      x2, y2 = rotate(-1*SW/2,  1*SH/2, sx, sy, rad)
      context.line_to(x2, y2)
      x3, y3 = rotate(-1*SW/2, -1*SH/2, sx, sy, rad)
      context.line_to(x3, y3)
      x4, y4 = rotate( 1*SW/2, -1*SH/2, sx, sy, rad)
      context.line_to(x4, y4)
      context.close_path
      context.stroke

      deg -= 60 / ((deg / 360).abs)
    end
  end

  # 点(x,y)を(cx,cy)を中心にrad[ラジアン]回転させる
  def rotate(x, y, cx, cy, rad)
    rotation = Matrix[[cos(rad), -sin(rad)], [sin(rad), cos(rad)]]
    rotated = rotation * Matrix.column_vector([x, y])
    rx = cx + rotated[0, 0].to_i
    ry = cy + rotated[1, 0].to_i
    # p sprintf("%d5 %d5, %d5 %d5 -> %d5, %d5", cx, x, cy, y, rx, ry)
    return [rx, ry]
  end
end

class Piers
  M_LENGTH = 80
  N_LENGTH = 8
  MN_GAP = M_LENGTH - N_LENGTH
  D_LENGTH = Field::ROUTE_WIDTH / 4

  def initialize
    @length = Field::OUTER_R - Field::CENTER_R
    @piers = Array.new(4).map { Array.new }
    for i in 0..3
      for j in 0..3
        s = (Field::CENTER_R + i * D_LENGTH + j * Field::ROUTE_WIDTH + Field::ROUTE_WIDTH * 0.3).round
        e = (Field::CENTER_R + i * D_LENGTH + j * Field::ROUTE_WIDTH + Field::ROUTE_WIDTH * 0.7).round
        @piers[i] << { from: s, to: e }
      end
    end
    @piers[0][0][:move_x] = M_LENGTH + 24
    @piers[0][0][:move_y] = -24
    @piers[1][0][:move_x] = M_LENGTH + 24
    @piers[1][0][:move_y] = Board::CY - 48
    @piers[2][0][:move_x] = M_LENGTH + 24
    @piers[2][0][:move_y] = Board::CY * 2 - 60
    @piers[3][0][:move_x] = 0
    @piers[3][0][:move_y] = 0
  end

  def draw_hole(context)
    for i in 0..3
      @piers[i].each {|t|
        context.move_to(t[:from], 0)
        context.line_to(t[:from], Board::THICK)
        context.line_to(t[:to], Board::THICK)
        context.line_to(t[:to], 0)
        context.close_path
        context.stroke
      }
      context.rotate(-90 * PI / 180)
    end
  end

  def draw_piers(context)
    for i in 0..3
      context.rotate(-180 * PI / 180)
      context.move_to(0, 0)
      level = Piers::N_LENGTH
      context.line_to(level, 0)
      @piers[i].each {|t|
        hole_s = t[:from] - Field::CENTER_R
        hole_e = t[:to] - Field::CENTER_R
        route_s = hole_s - Field::ROUTE_WIDTH * 0.3
        route_e = hole_e + Field::ROUTE_WIDTH * 0.3
        context.line_to(level, route_s)
        level = Piers::N_LENGTH + MN_GAP * (route_s / @length)
        context.line_to(level, route_s)
        context.line_to(level, hole_s)
        context.line_to(level + Board::THICK, hole_s)
        context.line_to(level + Board::THICK, hole_e)
        context.line_to(level, hole_e)
        context.line_to(level, route_e)
      }
      context.line_to(level, @length)
      context.line_to(0, @length)
      context.close_path
      context.stroke

      context.translate(@piers[i][0][:move_x], @piers[i][0][:move_y])
    end
  end

  def draw_stopper(context)
    context.translate(36, 3)
    for i in 1..8
      context.move_to(0, 0)
      context.line_to(16, 0)
      context.line_to(16, 16 - Board::THICK / 2)
      context.line_to( 8, 16 - Board::THICK / 2)
      context.line_to( 8, 16 + Board::THICK / 2)
      context.line_to(16, 16 + Board::THICK / 2)
      context.line_to(16, 32)
      context.line_to( 0, 32)
      context.close_path
      context.stroke

      context.translate(0, 40)
    end
  end
end

class Ant
  NUM = 8

  def draw_ants(context)
    context.translate(36, -320)
    for i in 1..NUM
      context.arc(24, 24, 22, PI, 2 * PI)

      context.move_to(2, 24)
      context.line_to(24 - Board::THICK / 2, 24)
      context.line_to(24 - Board::THICK / 2, 48)
      context.line_to(24 + Board::THICK / 2, 48)
      context.line_to(24 + Board::THICK / 2, 24)
      context.line_to(46, 24)
      context.stroke

      context.translate(0, 60)
    end
  end
end

field = Field.new
piers = Piers.new
ant = Ant.new

Cairo::SVGSurface.new("antlion_line.svg", Board::WIDTH, Board::HEIGHT) do |surface|
  context = Cairo::Context.new(surface)
  context.set_source_color(Cairo::Color::RED)
  context.save #reset

  context.translate(Field::CX, Field::CY)
  field.draw_field(context)
  field.draw_border(context)

  context.save
  field.draw_step(context)
  context.restore

  piers.draw_hole(context)
  context.translate(Field::CX - 7, 0)
  piers.draw_piers(context)

  context.restore # reset
  piers.draw_stopper(context)
  ant.draw_ants(context)
end

Cairo::SVGSurface.new("antlion_print.svg", Board::WIDTH, Board::HEIGHT) do |surface|
  context = Cairo::Context.new(surface)
  context.set_source_color(Cairo::Color::BLUE)

end

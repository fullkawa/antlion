# このスクリプトは tompng 氏に作っていただいたスクリプトをアレンジしたものです。
# @see https://gist.github.com/tompng/7624562

require 'chunky_png'

class Texture
  attr_accessor :img,:width,:height
  def initialize file
    @img=ChunkyPNG::Image.from_file file
    @width=img.width
    @height=img.height
  end
  def [] x,y
    return 1 unless (0...1).include?(x)&&(0...1).include?(y)
    ix,x=(x*(width-1)).divmod 1
    iy,y=(y*(height-1)).divmod 1
    (
      ChunkyPNG::Color.r(img[ix,iy])*(1-x)*(1-y)+
      ChunkyPNG::Color.r(img[ix+1,iy])*x*(1-y)+
      ChunkyPNG::Color.r(img[ix,iy+1])*(1-x)*y+
      ChunkyPNG::Color.r(img[ix+1,iy+1])*x*y
    ).fdiv 0xff
  end
end



texture=Texture.new 'ant.png'


def face p1,p2,p3,flip=false
  puts "facet normal 0 0 0"
  puts "outer loop"
  [p1,p2,p3].each do |p|
    puts "vertex #{p[:x]} #{p[:y]} #{p[:z]}"
  end
  puts "endloop"
  puts "endfacet"
end

def object name='name'
  puts "solid #{name}"
  begin
    yield
  ensure
    puts "endsolid #{name}"
  end
end

object 'ant' do
  size=200 #orig:256
  z=0.01 #orig:0.1
  p=->ix,iy{
    x=ix.fdiv(size)
    y=iy.fdiv(size)
    {
      x:x,
      y:y,
      z:0.15*(1-texture[x,y])+z #orig:0.05
    }
  }
  (size-1).times{|x|(size-1).times{|y|
    face p[x,y],p[x+1,y],p[x+1,y+1]
    face p[x,y],p[x+1,y+1],p[x,y+1]
  }}
  p0=[{x:0,y:0,z:0},{x:1,y:0,z:0},{x:1,y:1,z:0},{x:0,y:1,z:0}]
  p1=[{x:0,y:0,z:z},{x:1,y:0,z:z},{x:1,y:1,z:z},{x:0,y:1,z:z}]
  #底
  face p0[0],p0[1],p0[2],true
  face p0[0],p0[2],p0[3],true
  #側面
  4.times{|i|
    face p0[i-1],p0[i],p1[i]
    face p0[i-1],p1[i],p1[i-1]
  }

end

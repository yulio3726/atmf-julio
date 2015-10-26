class LocationsController < ApplicationController
  
  
  
  def poivisited
    uploaded_file = params[:file]
    @file_content = uploaded_file.read
    @objson = JSON.parse(@file_content)
    ruta = @objson.fetch("route")
    @locations = Location.all
    @visitedplaces = Array.new

    ruta.each do |point|
      location = Location.new
      location.latitude = point["latitude"]
      location.longitude = point["longitude"]
      @visitedplaces = @visitedplaces | where?(location, @locations,50)
    end
  end
  
  def visited
  end
  
  def convex
    
    @locations = Location.all
    @myHouse = Location.find_by_name("Casa julio")
    points = Array.new
    @locations.each do |location|
      points << [
      location[:latitude], location[:longitude], location[:id]]
    end
    
    points = calculate_convex_hull(points)
    @convex_locations = Array.new()
    points.each do |point|
      @convex_locations << Location.find_by_id(point)
    end
    
    @locations_json = @convex_locations.to_json
    perimeter_convex_hull = Array.new()
    i = @convex_locations.size
    until i < 1
      i -= 1
      perimeter_convex_hull << [@convex_locations[i][:name], @convex_locations[i-1][:name], distance(@convex_locations[i], @convex_locations[i-1])]
      @perimeter =  0
      perimeter_convex_hull.each do |data|
        @perimeter += data[2]
      end
    end
   
    @longest_distance = [['Casa julio', 0]]
    distance = 0
    
    @locations.each do |location|
      distance = distance(@myHouse, location)
      if distance > @longest_distance[@longest_distance.size-1][1]
        @longest_distance << [location[:name], distance]
      end
    end
  end
  
  def radiorespuesta
    
    parametros = JSON.parse(location_params.to_json)
    latitude = parametros["latitude"].to_f
    longitude = parametros["longitude"].to_f
    @radio = parametros["radio"].to_f
    
    @location = Location.new()
    @location["latitude"] = latitude
    @location["longitude"] = longitude
   
    @locations = Location.all
    @answer = where?(@location, @locations, @radio)
  end 

  def radio
  end
  
  def index
    # get all locations in the table locations
    @locations = Location.all

    # to json format
    @locations_json = @locations.to_json
  end

  def new
    # default: render ’new’ template (\app\views\locations\new.html.haml)
  end

  def create
    # create a new instance variable called @location that holds a Location object built from the data the user submitted
    @location = Location.new(location_params)

    # if the object saves correctly to the database
    if @location.save
      # redirect the user to index
      redirect_to locations_path, notice: 'Location was successfully created.'
    else
      # redirect the user to the new method
      render action: 'new'
    end
  end

  def edit
    # find only the location that has the id defined in params[:id]
    @location = Location.find(params[:id])
  end

  def update
    # find only the location that has the id defined in params[:id]
    @location = Location.find(params[:id])

    # if the object saves correctly to the database
    if @location.update_attributes(location_params)
      # redirect the user to index
      redirect_to locations_path, notice: 'Location was successfully updated.'
    else
      # redirect the user to the edit method
      render action: 'edit'
    end
  end

  def destroy
    # find only the location that has the id defined in params[:id]
    @location = Location.find(params[:id])

    # delete the location object and any child objects associated with it
    @location.destroy

    # redirect the user to index
    redirect_to locations_path, notice: 'Location was successfully deleted.'
  end

  def destroy_all
    # delete all location objects and any child objects associated with them
    Location.destroy_all

    # redirect the user to index
    redirect_to locations_path, notice: 'All locations were successfully deleted.'
  end

  def show
    # default: render ’show’ template (\app\views\locations\show.html.haml)
  end

  private

  def location_params
    params.require(:location).permit(:latitude, :longitude, :description, :name)
  end
  
  def power(num, pow)
    num ** pow
  end

  def distance(l1,l2)
    lat1 = l1.latitude
    long1 = l1.longitude
    lat2 = l2.latitude
    long2 = l2.longitude

    dtor = Math::PI/180
    r = 6378.14*1000

    rlat1 = lat1 * dtor
    rlong1 = long1 * dtor
    rlat2 = lat2 * dtor
    rlong2 = long2 * dtor

    dlon = rlong1 - rlong2
    dlat = rlat1 - rlat2

    a = power(Math::sin(dlat/2), 2) + Math::cos(rlat1) * Math::cos(rlat2) * power(Math::sin(dlon/2), 2)
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))
    d = r * c
    return d.round
  end

  def inside?(l1,l2,r)
    distancia = distance(l1,l2)
    if distancia > r
     return false
    else
      return true
    end
  end

  def where?(l1,locations,r)
    lugares = Array.new
    locations.each{|x|
    if inside?(l1,x,r)
      lugares.push(x.name)
    end
    }
    return lugares
  end
  
  def calculate_convex_hull(points)
    
    points.sort!.uniq!
    return points if points.length < 3
    
    def cross(o, a, b)
      (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    end
    
    lower = Array.new
    points.each{|p|
      while lower.length > 1 and cross(lower[-2], lower[-1], p) <= 0 do lower.pop end
      lower.push(p)
    }
    
    upper = Array.new
    points.reverse_each{|p|
      while upper.length > 1 and cross(upper[-2], upper[-1], p) <= 0 do upper.pop end
      upper.push(p)
    }
    
    return lower[0...-1] + upper[0...-1]
  end
 
end

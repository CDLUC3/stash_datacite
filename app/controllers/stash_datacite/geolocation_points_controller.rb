require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class GeolocationPointsController < ApplicationController
    before_action :set_geolocation_point, only: [:edit, :update, :delete]

    def index
      respond_to do |format|
        @geolocation_points = GeolocationPoint.only_geo_points(params[:resource_id])
        @resource = StashDatacite.resource_class.find(params[:resource_id])
        format.js
      end
    end

    # GET Leaflet AJAX index
    def points_coordinates
      respond_to do |format|
        @geolocation_points = GeolocationPoint.select(:resource_id, :id, :latitude, :longitude)
                                              .only_geo_points(params[:resource_id])
        format.html
        format.json { render json:  @geolocation_points }
      end
    end

    # POST Leaflet AJAX create
    def map_coordinates
      geo = geolocation_by_point(params)
      unless geo
        geo = Geolocation.new_geolocation(point: [params[:latitude], params[:longitude]],
                                          resource_id: params[:resource_id])
      end
      @geolocation_point = geo.geolocation_point
      respond_to do |format|
        format.json { render json: @geolocation_point.id }
      end
    end

    # POST Leaflet AJAX update
    def update_coordinates
      @geolocation_point = GeolocationPoint.where(id: params[:id]).from_resource_id(params[:resource_id]).first
      p = params.except(:controller, :action)
      respond_to do |format|
        if @geolocation_point.update(latitude: p[:latitude], longitude: p[:longitude])
          format.json { render json: @geolocation_point.id }
        else
          format.html { render :new }
        end
      end
    end

    # POST /geolocation_points
    def create
      geo = geolocation_by_point(params[:geolocation_point])
      unless geo
        pt_params = params[:geolocation_point]
        geo = Geolocation.new_geolocation(point: [pt_params[:latitude], pt_params[:longitude]],
                                          resource_id: params[:resource_id])
      end
      @geolocation_point = geo.geolocation_point
      @resource = StashDatacite.resource_class.find(params[:resource_id])
      respond_to do |format|
        @geolocation_points = GeolocationPoint.only_geo_points(params[:resource_id])
        format.js
      end
    end

    # DELETE /geolocation_points/1 && # DELETE Leaflet AJAX update
    def delete
      @latitude = @geolocation_point.latitude
      @longitude = @geolocation_point.longitude
      @geolocation_point.try(:geolocation).try(:destroy_point)
      @resource = StashDatacite.resource_class.find(params[:resource_id])
      @geolocation_points = GeolocationPoint.only_geo_points(params[:resource_id])
      respond_to do |format|
        format.js
      end
    end

    private

    # geolocation exists with params resource_id, latitude, longitude
    def geolocation_by_point(object_params)
      pt_params = object_params
      points = GeolocationPoint.only_geo_points(params[:resource_id])
                               .where(latitude: pt_params[:latitude], longitude: pt_params[:longitude])
      return nil if points.empty?
      points.first.geolocation
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_geolocation_point
      @geolocation_point = GeolocationPoint.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def geolocation_point_params
      params.require(:geolocation_point).permit(:id, :latitude, :longitude, :resource_id)
    end
  end
end

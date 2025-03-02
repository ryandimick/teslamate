defmodule TeslaMate.Log.Drive do
  use Ecto.Schema
  import Ecto.Changeset

  alias TeslaMate.Locations.{Address, GeoFence}
  alias TeslaMate.Log.{Position, Car}

  schema "drives" do
    field :start_date, :utc_datetime_usec
    field :end_date, :utc_datetime_usec
    field :outside_temp_avg, :float
    field :inside_temp_avg, :float
    field :speed_max, :integer
    field :power_max, :float
    field :power_min, :float
    field :power_avg, :float
    field :start_ideal_range_km, :float
    field :end_ideal_range_km, :float
    field :start_rated_range_km, :float
    field :end_rated_range_km, :float
    field :start_km, :float
    field :end_km, :float
    field :distance, :float
    field :duration_min, :integer

    belongs_to :start_position, Position
    belongs_to :end_position, Position

    belongs_to :start_address, Address
    belongs_to :end_address, Address

    belongs_to :start_geofence, GeoFence
    belongs_to :end_geofence, GeoFence

    belongs_to :car, Car

    has_many :positions, Position, on_delete: :delete_all
  end

  @doc false
  def changeset(drive, attrs) do
    drive
    |> cast(attrs, [
      :start_date,
      :end_date,
      :start_address_id,
      :end_address_id,
      :start_position_id,
      :end_position_id,
      :start_geofence_id,
      :end_geofence_id,
      :outside_temp_avg,
      :inside_temp_avg,
      :speed_max,
      :power_max,
      :power_min,
      :power_avg,
      :start_ideal_range_km,
      :end_ideal_range_km,
      :start_rated_range_km,
      :end_rated_range_km,
      :start_km,
      :end_km,
      :distance,
      :duration_min
    ])
    |> validate_required([:car_id, :start_date])
    |> foreign_key_constraint(:car_id)
    |> foreign_key_constraint(:start_address_id)
    |> foreign_key_constraint(:end_address_id)
    |> foreign_key_constraint(:start_geofence_id)
    |> foreign_key_constraint(:end_geofence_id)
    |> foreign_key_constraint(:start_position_id)
    |> foreign_key_constraint(:end_position_id)
  end
end

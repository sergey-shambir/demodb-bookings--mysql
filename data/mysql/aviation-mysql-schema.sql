CREATE TABLE aircrafts_data (
  aircraft_code CHAR(3) NOT NULL,
  model JSON NOT NULL,
  `range` INT NOT NULL,
  PRIMARY KEY (aircraft_code),
  CONSTRAINT aircrafts_range_check
    CHECK ((`range` > 0))
);

CREATE TABLE airports_data (
  airport_code CHAR(3) NOT NULL,
  airport_name JSON NOT NULL,
  city JSON NOT NULL,
  coordinates VARCHAR(1000) NOT NULL,
  timezone VARCHAR(40) NOT NULL,
  PRIMARY KEY (airport_code)
);

CREATE TABLE flights (
  flight_id INT NOT NULL AUTO_INCREMENT,
  flight_no CHAR(6) NOT NULL,
  scheduled_departure DATETIME NOT NULL,
  scheduled_arrival DATETIME NOT NULL,
  departure_airport CHAR(3) NOT NULL,
  arrival_airport CHAR(3) NOT NULL,
  status VARCHAR(20) NOT NULL,
  aircraft_code CHAR(3) NOT NULL,
  actual_departure DATETIME,
  actual_arrival DATETIME,
  PRIMARY KEY (flight_id),
  CONSTRAINT flights_flight_no_scheduled_departure_key
    UNIQUE (flight_no, scheduled_departure),
  CONSTRAINT flights_aircraft_code_fkey
    FOREIGN KEY (aircraft_code)
      REFERENCES aircrafts_data(aircraft_code),
  CONSTRAINT flights_arrival_airport_fkey
    FOREIGN KEY (arrival_airport)
      REFERENCES airports_data(airport_code),
  CONSTRAINT flights_departure_airport_fkey
    FOREIGN KEY (departure_airport)
      REFERENCES airports_data(airport_code),
  /**
    NOTE: removed checks that do no pass in existing data
   */
#   CONSTRAINT flights_check
#     CHECK ((scheduled_arrival > scheduled_departure)),
#   CONSTRAINT flights_check1
#     CHECK (((actual_arrival IS NULL) OR
#             ((actual_departure IS NOT NULL) AND (actual_arrival IS NOT NULL) AND
#              (actual_arrival > actual_departure)))),
  CONSTRAINT flights_status_check
    CHECK (status IN ('On Time', 'Delayed', 'Departed', 'Arrived', 'Scheduled', 'Cancelled'))
);

CREATE TABLE seats (
  aircraft_code CHAR(3) NOT NULL,
  seat_no VARCHAR(4) NOT NULL,
  fare_conditions VARCHAR(10) NOT NULL,
  PRIMARY KEY (aircraft_code, seat_no),
  CONSTRAINT seats_aircraft_code_fkey
    FOREIGN KEY (aircraft_code)
      REFERENCES aircrafts_data(aircraft_code)
      ON DELETE CASCADE,
  CONSTRAINT seats_fare_conditions_check
    CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business'))
);

CREATE TABLE bookings (
  book_ref CHAR(6) NOT NULL,
  book_date DATETIME NOT NULL,
  total_amount DECIMAL(10, 2) NOT NULL,
  PRIMARY KEY (book_ref)
);

CREATE TABLE tickets (
  ticket_no CHAR(13) NOT NULL,
  book_ref CHAR(6) NOT NULL,
  passenger_id VARCHAR(20) NOT NULL,
  passenger_name TEXT NOT NULL,
  contact_data JSON,
  PRIMARY KEY (ticket_no),
  CONSTRAINT tickets_book_ref_fkey
    FOREIGN KEY (book_ref)
      REFERENCES bookings(book_ref)
);

CREATE TABLE ticket_flights (
  ticket_no CHAR(13) NOT NULL,
  flight_id INTEGER NOT NULL,
  fare_conditions VARCHAR(10) NOT NULL,
  amount NUMERIC(10, 2) NOT NULL,
  PRIMARY KEY (ticket_no, flight_id),
  CONSTRAINT ticket_flights_ticket_no_fkey
    FOREIGN KEY (ticket_no)
      REFERENCES tickets(ticket_no),
  CONSTRAINT ticket_flights_flight_id_fkey
    FOREIGN KEY (flight_id)
      REFERENCES flights(flight_id),
  CONSTRAINT ticket_flights_amount_check
    CHECK ((amount >= 0)),
  CONSTRAINT ticket_flights_fare_conditions_check
    CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business'))
);

CREATE TABLE boarding_passes (
  ticket_no CHAR(13) NOT NULL,
  flight_id INT NOT NULL,
  boarding_no INT NOT NULL,
  seat_no VARCHAR(4) NOT NULL,
  PRIMARY KEY (ticket_no, flight_id),
  CONSTRAINT boarding_passes_flight_id_boarding_no_key
    UNIQUE KEY (flight_id, boarding_no),
  CONSTRAINT boarding_passes_flight_id_seat_no_key
    UNIQUE KEY (flight_id, seat_no)
);

/*
    NOTE: removed following foreign key
    - MySQL cannot create composite foreign keys

    CONSTRAINT boarding_passes_ticket_no_fkey
    FOREIGN KEY (ticket_no, flight_id)
      REFERENCES ticket_flights (ticket_no, flight_id)
*/

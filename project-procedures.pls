-- Member 1 Procedures
create or replace procedure AddService(Res_id in number,--in equals input
                                       ser_type in varchar2,-- input
                                       ser_id in NUMBER,--input
                                       date_of_ser in date)--input
    is
begin

    --
    insert into customer_service_invoices(Reservation_id, service_id, date_of_service)
    values (Res_id, ser_type, date_of_ser);

end;



CREATE OR REPLACE PROCEDURE Res_ser_report(
    Res_id in NUMBER -- input
)
as
    CURSOR res_ser_rep is select service_type
                          from services,
                               customer_service_invoices
                          where customer_service_invoices.service_id = services.service_id
                            and reservation_id = res_id;--create a cursor
    cust_serv_invoice_row res_ser_rep%rowtype;-- rowtype local variable
    count                 int;
BEGIN
    select count(*) into count from services, customer_service_invoice
        where customer_service_invoices.service_id = services.service_id and reservation_id = res_id;
    if count > 0 then
        for cust_serv_invoice_row in res_ser_rep
            LOOP
                dbms_output.put_line('services for this res_id are:' || cust_serv_invoice_row.service_type)
            end loop;
    else
        dbms_output.put_line('no services were found on resveration id.');
    end if;
end;

--     Output example: service type, and service id, res_id, name of guest and hotel id
-- Show Specific Service Report: Input the service name, and display information on all reservations that have this service in all hotels
CREATE OR REPLACE PROCEDURE spec_ser_rep(
    ser_type in NUMBER -- input for the service type column
)
as
CURSOR specific_row is select service_type from services, customer_service_invoices
    where customer_service_invoices.service_id = services.service_id and service_type = ser_type;--create a cursor
specific_rowtype specific_row%rowtype;-- rowtype local variable
COUNTER int;
BEGIN
    select COUNT(*) into COUNTER from services, customer_service_invoices where customer_service_invoices.service_id = services.service_id and service_type = ser_type;
    IF COUNT > 0 then
        FOR specific_rowtype in specific_row
        LOOP
            dbms_output.put_line('services for this res_id are:'||specific_rowtype.service_type ||’, ’||specific_rowtype.reservation_id||);

        END LOOP;
    ELSE
        dbms_output.put_line('this service type is currently not being used.' );
    END IF ;
END;

-- input: hotel id
-- income from all services in all res in hotel
-- what services are being used and calculate the income
-- breakdown income by service type and display service name and income
-- Total Services Income Report: Given a hotelID, calculate and display income from all services in all reservations in that hotel.

CREATE OR REPLACE PROCEDURE total_services_income_report(
    hot_id IN NUMBER --input variable for hotel id
)
as
CURSOR specific_row is select SUM(service_rate) from services, reservations, customer_service_invoices
    where reservations.reservation_id = customer_service_invoices.reservation_id and
hotel_id  = hot_id ; --create a cursor
specific_rowtype specific_row%rowtype;-- rowtype local variable
COUNTER int;
BEGIN
    select COUNT(*) into COUNTER from services, reservations, customer_service_invoices
        where reservations.reservation_id = customer_service_invoices.reservation_id and hotel_id  = hot_id ;
    IF COUNTER > 0 then
        FOR specific_rowtype in specific_row
        LOOP
            dbms_output.put_line('services for this res_id are: '||specific_rowtype.service_rate ||', '||specific_rowtype.reservation_id||', '||specific_rowtype.service_type);
        END LOOP;
    ELSE
        dbms_output.put_line('this service type is currently not being used.' );
    END IF;
END;


-- Member 2 Procedures

CREATE OR REPLACE PROCEDURE MakeReservation(
    p_hotel_id IN NUMBER, -- hotel identifier
    p_guest_name IN VARCHAR2, -- customer name
    p_start_date IN DATE, -- expected check in time
    p_end_date IN DATE,  -- expected checkout time
    p_room_type IN VARCHAR2,  -- type of room
    p_date_of_reservation IN DATE,  -- time request was made
    o_reservation_id OUT NUMBER) -- confirmation num
IS
    invalid_hotel_ex EXCEPTION;
    invalid_guest_ex EXCEPTION;
    v_hotel_cnt NUMBER;
    v_customer_cnt NUMBER;
    v_customer_id NUMBER;
BEGIN
    -- Verify Hotel ID parameter.
    SELECT COUNT(HOTEL_ID) INTO v_hotel_cnt FROM HOTELS WHERE HOTEL_ID=p_hotel_id;
    if (NOT v_hotel_cnt=1) then
        -- No Valid Hotel, given Hotel ID.
        raise invalid_hotel_ex;
    end if;
    -- Verify Guest Name parameter.
    SELECT COUNT(*) INTO v_customer_cnt FROM CUSTOMERS WHERE CUSTOMER_NAME=p_guest_name;
    if (v_customer_cnt=1) then
        -- Get Customer ID.
        SELECT CUSTOMER_ID INTO v_customer_id FROM CUSTOMERS WHERE CUSTOMER_NAME=p_guest_name;
    else
        -- No valid customer ID, given guest name.
        raise invalid_guest_ex;
    end if;
    -- Set next reservation id
    o_reservation_id := reservations_seq.nextval;
    -- Insert user values.
    INSERT INTO RESERVATIONS VALUES (o_reservation_id, p_date_of_reservation, v_customer_id, p_hotel_id, p_start_date,
                                     NULL, p_end_date, NULL, 0, p_room_type);
EXCEPTION
    WHEN invalid_hotel_ex THEN
        DBMS_OUTPUT.PUT('There is no record for the given HOTEL_ID: ');
        DBMS_OUTPUT.PUT(p_hotel_id);
        DBMS_OUTPUT.PUT_LINE('!');
    WHEN invalid_guest_ex THEN
        DBMS_OUTPUT.PUT('There is no customer record for the given GUEST_NAME: ');
        DBMS_OUTPUT.PUT(p_guest_name);
        DBMS_OUTPUT.PUT_LINE('!');
END;

CREATE OR REPLACE PROCEDURE FindReservation(p_guest_name IN VARCHAR2, -- customer name
                                            p_reservation_date IN DATE, -- date of reservation
                                            p_hotel_id IN NUMBER, -- hotel identifier
                                            o_reservation_id OUT NUMBER) -- the reservation
IS
    invalid_guest_ex EXCEPTION;
    v_customer_id NUMBER;
    v_customer_cnt NUMBER;
BEGIN
    -- Verify Guest Name parameter.
    SELECT COUNT(*) INTO v_customer_cnt FROM CUSTOMERS WHERE CUSTOMER_NAME=p_guest_name;
    if (v_customer_cnt=1) then
        -- Get Customer ID.
        SELECT CUSTOMER_ID INTO v_customer_id FROM CUSTOMERS WHERE CUSTOMER_NAME=p_guest_name;
    else
        -- No valid customer ID, given guest name.
        raise invalid_guest_ex;
    end if;
    -- Get the reservation ID.
    SELECT RESERVATION_ID INTO o_reservation_id FROM RESERVATIONS WHERE CUSTOMER_ID=v_customer_id AND
                                                                        HOTEL_ID=p_hotel_id AND
                                                                        RESERVATION_TIME=p_reservation_date;
EXCEPTION
    WHEN invalid_guest_ex THEN
        DBMS_OUTPUT.PUT_LINE('There is no customer record for the given GUEST_NAME: '|| p_guest_name || '!');
END;

CREATE OR REPLACE PROCEDURE CancelReservation(p_reservation_id IN NUMBER) IS
BEGIN
    UPDATE RESERVATIONS SET CANCELED=1 WHERE RESERVATION_ID=p_reservation_id;
    DBMS_OUTPUT.PUT_LINE('Canceled reservation ' || p_reservation_id || '!');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Cannot find reservation ' || p_reservation_id || '!');
END;

CREATE OR REPLACE PROCEDURE ShowCancellations IS
    CURSOR c_res IS SELECT RESERVATION_ID, HOTEL_ID, CUSTOMER_ID, ROOM_TYPE, EXPECTED_CHECK_IN_TIME,
                           EXPECTED_CHECK_OUT_TIME FROM RESERVATIONS;
    v_customer_name VARCHAR2(50);
    v_hotel_name VARCHAR2(50);
    v_hotel_city VARCHAR2(50);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Canceled Hotel Reservations:');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
    for r_res in c_res loop
        SELECT HOTEL_NAME, HOTEL_CITY INTO v_hotel_name, v_hotel_city FROM HOTELS WHERE HOTEL_ID=r_res.HOTEL_ID;
        SELECT CUSTOMER_NAME INTO v_customer_name FROM CUSTOMERS WHERE CUSTOMER_ID=r_res.CUSTOMER_ID;
        DBMS_OUTPUT.PUT('Reservation ID: ' || r_res.RESERVATION_ID || ', ');
        DBMS_OUTPUT.PUT('Hotel Name: ' || v_hotel_name || ', ');
        DBMS_OUTPUT.PUT('Location: ' || v_hotel_city || ', ');
        DBMS_OUTPUT.PUT('Guest Name: ' || v_customer_name || ', ');
        DBMS_OUTPUT.PUT('Room Type: ' || r_res.ROOM_TYPE || ', ');
        DBMS_OUTPUT.PUT('Expected Check-in Date: ' || r_res.EXPECTED_CHECK_IN_TIME || ', ');
        DBMS_OUTPUT.PUT_LINE('Expected Check-out Date: ' || r_res.EXPECTED_CHECK_OUT_TIME);
    end loop;
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
END;

-- Member 5 Procedures 
create or replace procedure showAvailableRooms (hotel_id_input in number) is
cursor roomie is 
select room_type, count(room_number) as blug 
from rooms, hotels where room_availability = 1 and hotel_id_input = hotel_id  
group by room_type;
roomie_row roomie%rowtype;
begin 
dbms_output.put_line('Hotel # ' || hotel_id_input || ' available rooms');
dbms_output.put_line('-----------------------------------');
for roomie_row in roomie 
    loop
    --dbms_output.put_line('Room type is ' || roomie_row.room_type || 'Available room count is ' || roomie_row.blug);
    dbms_output.put_line(roomie_row.blug || ' ' || roomie_row.room_type || ' rooms available :)');
    END LOOP;
    exception
    when others then 
    dbms_output.put_line('Unexpected error has occured'); 
end;

create or replace procedure checkoutreport (
    in_res_id in number
    )        
is
    cus_nam VARCHAR2(50);
    hotel_num_stor number;
    hotel_name_stor VARCHAR2(50);
    roomNumber NUMBER NULL;
    rum_rate NUMBER NULL;
    serv_typo VARCHAR2(50);
    serv_dato date;
    serv_rato number;
    DISCOUNT NUMBER;
    TOTAL_SRV_AMOUNT NUMBER;
    TOTAL_ROOM_AMOUNT_WD NUMBER;
    TOTAL_ROOM_AMOUNT NUMBER;
     
    cursor room_cursorS is 
        select reservation_room 
        from customer_room_invoices 
        where reservation_id = in_res_id;
        
    room_cursor customer_room_invoices%ROWTYPE;
    
    cursor room_rate_cursorS is
        select room.room_rate 
        from customer_room_invoices 
        inner join rooms room on room.room_number = customer_room_invoices.reservation_room and room.room_hotel = customer_room_invoices.reservation_hotel 
        where customer_room_invoices.reservation_id = in_res_id;
        
    room_rate_cursor customer_room_invoices%ROWTYPE;

begin
    select customer_name
    into cus_nam
    from reservations r
    inner join customersGP c on r.customer_id = c.customer_id
    where r.reservation_id = in_res_id;
    
    dbms_output.put_line('The customers name is ' || cus_nam);
    
    select hotel_id
    into hotel_num_stor
    from reservations r
    where r.reservation_id = in_res_id;
    
    dbms_output.put_line('Hotel Number: ' || hotel_num_stor);

    select hotel_name 
    into hotel_name_stor
    from hotels , reservations
    where in_res_id = reservations.reservation_id and reservations.hotel_id = hotels.hotel_id;

    dbms_output.put_line('Hotel Name: ' || hotel_name_stor);
   
    for room_cursor in room_cursorS 
        loop
            if (room_cursorS%rowcount = 1) then
                dbms_output.new_line();
            end
                if;
                dbms_output.put_line('Room Number ' || room_cursor.reservation_room || ' is on this reservation.');
        end loop;

  

    for room_rate_cursor in room_rate_cursorS
        loop
            if (room_rate_cursorS%rowcount = 1) then 
                dbms_output.put_line('Room rates listed in order of room numer:');
            end
                if;
                dbms_output.put_line(room_rate_cursor.room_rate || ' is the room rate per day');
        end loop;
        
        dbms_output.new_line();
        
SELECT CAST( CASE 
        WHEN  ABS(TO_DATE(reservation_time)- TO_DATE(check_in_time)) >= 30 
            THEN 1 
            ELSE 0  
     END as int ) 
    INTO DISCOUNT
    FROM reservations r
    where r.reservation_id = in_res_id; 

select SUM(c_inv.service_amount)
    INTO TOTAL_SRV_AMOUNT
     FROM reservations r
     INNER JOIN customer_service_invoices  c_inv on c_inv.reservation_id = r.reservation_id
    where r.reservation_id = in_res_id;

select
DISTINCT( CAST(CASE WHEN EXTRACT(month from check_in_time) > 4 and EXTRACT(month from check_in_time) < 9
            THEN CASE
                WHEN room.room_type = 'single'
                    THEN room.room_rate + 200
                    ELSE CASE WHEN room.room_type = 'doule'
                            THEN  room.room_rate+ 300
                            ELSE  CASE WHEN room.room_type = 'suite'
                                    THEN  room.room_rate+ 400
                                    ELSE  room.room_rate+ 4000 
                                    END
                        END
                END
            ELSE room.room_rate 
            END as  NUMBER(4,0) )
            *  ABS(TO_DATE(check_out_time)- TO_DATE(check_in_time))
            )
      as total_amount_without_discount
      INTO TOTAL_ROOM_AMOUNT_WD
FROM reservations r
Inner join customersGP  c on r.customer_id= c.customer_id
INNER JOIN customer_room_invoices  inv on inv.reservation_id=r.reservation_id 
INNER JOIN rooms room on room.room_number = inv.reservation_room  and room.room_hotel = inv.reservation_hotel
INNER JOIN customer_service_invoices  c_inv on c_inv.reservation_id = r.reservation_id
INNER JOIN services  s on s.service_id = c_inv.service_id
where r.reservation_id = in_res_id;

CASE WHEN DISCOUNT = 1
        THEN TOTAL_ROOM_AMOUNT :=  TOTAL_SRV_AMOUNT + TOTAL_ROOM_AMOUNT_WD*0.1 ;
        ELSE TOTAL_ROOM_AMOUNT := TOTAL_SRV_AMOUNT + TOTAL_ROOM_AMOUNT_WD;
END CASE;

select distinct
s.service_rate, s.service_type, s.service_date
into serv_rato, serv_typo, serv_dato
from customer_service_invoices c_inv
inner join services s on s.service_id = c_inv.service_id and c_inv.reservation_id = in_res_id;

dbms_output.put_line('Services:');
dbms_output.put_line(serv_typo || ' , ' || serv_dato || ' , $' || serv_rato);
dbms_output.new_line();
dbms_output.put_line('Total Owed: $' || TOTAL_ROOM_AMOUNT);

EXCEPTION
    when others then 
        dbms_output.put_line('An error has occurred!');


end;
                   
create or replace procedure incomeByStateReport (in_state_id in char) 

is  

    data_not_found exception;
    res_id_hold number;
    hotel_id_hold number;
    randomint number := 0;
    otherint number:= 0;
    DISCOUNT NUMBER:=0;
    TOTAL_SRV_AMOUNT NUMBER;
    TOTAL_ROOM_AMOUNT_WD NUMBER;
    TOTAL_ROOM_AMOUNT NUMBER;
    room_rate_hold number(4,0);
    room_type_hold VARCHAR2(15);
    room_num_hold number;
    single_total number:=0;
    double_total number:=0;
    suite_total number:=0;
    confrence_total number:=0;
    food_total number:=0;
    ppv_total number:=0;
    laundry_total number:=0;
    serv_typo VARCHAR2(50);
    serv_rato number:=0;
    income_total number;
    cus_nam VARCHAR2(50);

    cursor hotel_cursorS is
        select hotel_id
        from hotels h
        where hotel_state = in_state_id;
        
    cursor reservation_cursorS is
        select reservation_id
        from reservations
        where reservations.hotel_id = hotel_id_hold;
        
    hotel_cursor hotels%ROWTYPE;
    reservation_cursor reservations%ROWTYPE;

begin

dbms_output.put_line('State: ' || in_state_id);
dbms_output.new_line();




open hotel_cursorS;

loop
        
        fetch hotel_cursorS into hotel_id_hold;
        exit when hotel_id_hold = otherint;
        
        randomint := 0;
        
        open reservation_cursorS;
        
        
        loop
                 
                fetch reservation_cursorS into res_id_hold;
                
                SELECT CAST( CASE 
                         WHEN  ABS(TO_DATE(reservation_time)- TO_DATE(check_in_time)) >= 30 
                                THEN 1 
                                ELSE 0  
                    END as int ) 
                    INTO DISCOUNT
                    FROM reservations r
                    where r.reservation_id = res_id_hold;
                    
                select reservation_room
                into room_num_hold
                from customer_room_invoices
                where reservation_id = res_id_hold and reservation_hotel = hotel_id_hold;
                    
                select r.room_rate, r.room_type
                into room_rate_hold, room_type_hold
                from rooms r
                where room_number = room_num_hold and room_hotel = hotel_id_hold;
                    
                select SUM(c_inv.service_amount)
                    INTO TOTAL_SRV_AMOUNT
                    FROM reservations r
                    INNER JOIN customer_service_invoices  c_inv on c_inv.reservation_id = r.reservation_id
                    where r.reservation_id = res_id_hold;
                                        
                select
DISTINCT( CAST(CASE WHEN EXTRACT(month from check_in_time) > 4 and EXTRACT(month from check_in_time) < 9
            THEN CASE
                WHEN room.room_type = 'single'
                    THEN room.room_rate + 200
                    ELSE CASE WHEN room.room_type = 'doule'
                            THEN  room.room_rate+ 300
                            ELSE  CASE WHEN room.room_type = 'suite'
                                    THEN  room.room_rate+ 400
                                    ELSE  room.room_rate+ 4000 
                                    END
                        END
                END
            ELSE room.room_rate 
            END as  NUMBER(4,0) )
            *  ABS(TO_DATE(check_out_time)- TO_DATE(check_in_time))
            )
      as total_amount_without_discount
      INTO TOTAL_ROOM_AMOUNT_WD
FROM reservations r
Inner join customersGP  c on r.customer_id= c.customer_id
INNER JOIN customer_room_invoices  inv on inv.reservation_id=r.reservation_id 
INNER JOIN rooms room on room.room_number = inv.reservation_room  and room.room_hotel = inv.reservation_hotel
INNER JOIN customer_service_invoices  c_inv on c_inv.reservation_id = r.reservation_id
INNER JOIN services  s on s.service_id = c_inv.service_id
where r.reservation_id = res_id_hold;   

CASE WHEN DISCOUNT = 1
        THEN TOTAL_ROOM_AMOUNT :=  TOTAL_SRV_AMOUNT + TOTAL_ROOM_AMOUNT_WD*0.1 ;
        ELSE TOTAL_ROOM_AMOUNT := TOTAL_SRV_AMOUNT + TOTAL_ROOM_AMOUNT_WD;
END CASE;

select distinct
s.service_rate, s.service_type
into serv_rato, serv_typo
from customer_service_invoices c_inv
inner join services s on s.service_id = c_inv.service_id and c_inv.reservation_id = res_id_hold;


if room_type_hold = 'single' then single_total:= single_total + room_rate_hold; 
end if;

if room_type_hold = 'double' then double_total:= double_total + room_rate_hold; 
end if;

if room_type_hold = 'suite' then suite_total:= suite_total + room_rate_hold; 
end if;

if room_type_hold = 'confrence' then confrence_total:= confrence_total + room_rate_hold; 
end if;

if serv_typo = 'Food' then food_total:= food_total + TOTAL_SRV_AMOUNT;
end if;

if serv_typo = 'PPV' then ppv_total:= ppv_total + TOTAL_SRV_AMOUNT; 
end if;

if serv_typo = 'Laundry' then laundry_total:= laundry_total + TOTAL_SRV_AMOUNT; 
end if;
food_total:=20;
income_total:= single_total+double_total+suite_total+confrence_total+food_total+ppv_total+laundry_total;
                
                 randomint := randomint+1;
                 exit when randomint = 2;
                 
        end loop;
        
        close reservation_cursorS;
        
            
   
                 otherint := hotel_id_hold;  
end loop;
close hotel_cursorS;

dbms_output.put_line('The single total is: ' || single_total);

dbms_output.put_line('The double total is: ' || double_total);

dbms_output.put_line('The suite total is: ' || suite_total);

dbms_output.put_line('The confrence total is: ' || confrence_total);

dbms_output.put_line('The food total is: ' || food_total);
dbms_output.put_line('The ppv total is: ' || ppv_total);
dbms_output.put_line('The laundry total is: ' || laundry_total);
dbms_output.put_line('The income total is: ' || income_total);

exception
    when data_not_found then
    DISCOUNT:=0;
    when others then 
    dbms_output.put_line('The error code is ' || SQLCODE || ' ' || SQLERRM);
    
    


end;

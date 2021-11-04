--TP3 :LES FONCTIONS ET PROCEDURES ET DECLENCHEURS 
-----------EXERCICE 1 :LES PROCEDURES
--Q1

SET SERVEROUTPUT ON;

DECLARE
v_location_id locations.location_id%type;
last_warehouse warehouses.warehouse_id%type;
new_name warehouses.warehouse_name%type;

PROCEDURE AJOUTER_WAREHOUSE (v_location_id locations.location_id%type, last_warehouse warehouses.warehouse_id%type,new_name warehouses.warehouse_name%type) IS
BEGIN
INSERT INTO WAREHOUSES (warehouse_id,warehouse_name,location_id) VALUES (last_warehouse,new_name,v_location_id);
END;

BEGIN
v_location_id:=&v_location_id;
select max(warehouse_id)+1 into last_warehouse from warehouses;
new_name :='&new_name';
AJOUTER_WAREHOUSE(v_location_id,last_warehouse,new_name );
END;





--Q2 


SET SERVEROUTPUT ON;
DECLARE
v_location_id locations.location_id%type;
v_name warehouses.warehouse_name%type;
-----si on est censé de mettre à jour juste le nom du warehouse , on utilise la procédure suivante:
PROCEDURE UPDATE_WAREHOUSE (v_location_id locations.location_id%type,v_name warehouses.warehouse_name%type) IS
BEGIN
UPDATE WAREHOUSES SET warehouse_name = v_name WHERE location_id=v_location_id;
END;

BEGIN
v_location_id:=&v_location_id;
v_name:='&v_name';
UPDATE_WAREHOUSE(v_location_id,v_name);
END;

-----si on est censé de mettre à jour le nom du warehouse ainsi que son id on utilise la procédure suivante:

CREATE OR REPLACE PROCEDURE MOD_WAREHOUSE (v_warehouse_id IN warehouses.warehouse_id%type,
v_name  IN warehouses.warehouse_name%type) IS
BEGIN
UPDATE WAREHOUSES SET warehouse_name = v_name WHERE warehouse_id=v_warehouse_id;
END;


--Q3

SET SERVEROUTPUT ON;
DECLARE
v_location_id locations.location_id%type;

PROCEDURE DELETE_WAREHOUSE (v_location_id locations.location_id%type) IS
BEGIN
DELETE WAREHOUSES WHERE location_id=v_location_id;
END;

BEGIN
v_location_id:=&v_location_id;
DELETE_WAREHOUSE(v_location_id);
END;




--Q4



SET SERVEROUTPUT ON;
DECLARE
v_location_id locations.location_id%type;

TYPE  names is table of warehouses.warehouse_name%type ;
names_tab names;
PROCEDURE ALL_WAREHOUSE (v_location_id IN locations.location_id%type ,
TYPE  names is table of warehouses.warehouse_name%type) IS
BEGIN
names_tab names;
SELECT warehouse_name BULK COLLECT INTO into names_tab FROM warehouses  WHERE location_id=v_location_id;
END;
BEGIN
v_location_id:=&v_location_id;
ALL_WAREHOUSE(v_location_id,names);
/*for i in names_tab.FIRST .. names_tab.LAST loop
DBMS_OUTPUT.PUT_LINE(names_tab(i));
end loop;*/
END;





TYPE  warehouses_name is table of warehouses.warehouse_name%type ;
tab_WH_names2 warehouses_name;
PROCEDURE afficher(loc_id IN warehouses.location_id%TYPE , tab_WH_names OUT warehouses_name ) IS
BEGIN
SELECT warehouse_name Bulk collect  into tab_WH_names FROM warehouses 
WHERE location_id = loc_id ;
END;
BEGIN
afficher(11,tab_WH_names2);
SELECT COUNT(*) into total from warehouses where location_id = 11 ; 
for i in 1..total LOOP
DBMS_OUTPUT.PUT_LINE(tab_WH_names2(i));
END LOOP;
END;

--Q5 

SET SERVEROUTPUT ON;
DECLARE
v_employee_id EMPLOYEES.EMPLOYEE_ID%TYPE;
v_CA number;

PROCEDURE calcule_CA(id_employe IN EMPLOYEES.EMPLOYEE_ID%TYPE,
sum OUT number)IS

BEGIN

SELECT SUM(QUANTITY*UNIT_PRICE) into sum
FROM ORDERS
INNER JOIN ORDER_ITEMS USING(ORDER_ID)
INNER JOIN EMPLOYEES ON EMPLOYEES.EMPLOYEE_ID = ORDERS.SALESMAN_ID
WHERE EMPLOYEES.EMPLOYEE_ID=v_employee_id;

END;

BEGIN
v_employee_id:=&v_employee_id;
calcule_CA(v_employee_id,v_CA);
dbms_output.put_line('Le CA de :'||v_employee_id||' est : '||v_CA);
END;


-----------EXERCICE 2 :LES FONTIONS
--Q1
SET SERVEROUTPUT ON
DECLARE
   v_customer_id orders.customer_id%type;
   v_nbr NUMBER;
    FUNCTION somme_order(v_customer_id IN orders.customer_id%type )
    RETURN number
    IS
    v_nbr number;
    BEGIN
      SELECT SUM(QUANTITY*UNIT_PRICE) 
      INTO v_nbr
      FROM orders
      INNER JOIN order_items USING(order_id) 
      WHERE customer_id = v_customer_id;
      return v_nbr;
    END;
BEGIN
    v_customer_id:=&v_customer_id;
   v_nbr := somme_order(v_customer_id);
     DBMS_OUTPUT.PUT_LINE(v_nbr);
END;

--Q2

SET SERVEROUTPUT ON;
DECLARE
nbr_commande number;

FUNCTION Pending_commande
RETURN v_nbr 
IS
nombre v_nbr;

BEGIN
select count(*) INTO v_nbr from orders where STATUS='Pending';
return v_nbr;
END;

BEGIN
nombre_commande:=Pending_commande;
dbms_output.put_line('Le nombre de commande qui ont comme status: Pending est:  '||nombre_commande);
END;


-----EXERCICE 3 :Les DECLENCHEURS
Q1


create TRIGGER resume_order
    BEFORE INSERT ON ORDER_ITEMS
    FOR EACH ROW
DECLARE
BEGIN
DBMS_OUTPUT.PUT_LINE('order_id '|| :NEW.order_id);
DBMS_OUTPUT.PUT_LINE('order_quantity '|| :new.quantity);
DBMS_OUTPUT.PUT_LINE('order_price '|| :new.unit_price);
END;

--Q2

create  TRIGGER alerte_stock
   AFTER  UPDATE ON INVENTORIES
    FOR EACH ROW
DECLARE
BEGIN
if :NEW.quantity<10 then
DBMS_OUTPUT.PUT_LINE('ATTENTION LA QUANTITE EST <10');
end if ;
END;


--Q3
create  TRIGGER update_credit
    BEFORE UPDATE OF credit_limit  
    ON customers
DECLARE
    v_jour NUMBER;
BEGIN
    -- on extrait le jour  du system et on l'affecte à la variable v_jour pour vérifier par la suite
    v_jour := EXTRACT(DAY FROM sysdate);

    IF v_jour BETWEEN 28 AND 31 THEN
        dbms_output.put_line('impossible de modifier le credit_limit entre 28 &31');
    END IF;
END;

--Q4

create  TRIGGER dec_ajout_employee
    BEFORE INSERT ON EMPLOYEES 
    FOR EACH ROW

BEGIN
    
    IF sysdate < :NEW.hire_date THEN
        dbms_output.put_line('Impossible d'ajouter l'employé (today date<hire_date)');
    END IF;
END;

--Q5

create  TRIGGER remise_order
    BEFORE INSERT ON order_items
    FOR EACH ROW
DECLARE
--total final est la variable qui va stocker le prix avec remise
total_final number;
BEGIN
      if :New.unit_price*:NEW.Quantity > 10000 then
     total_final:=:New.unit_price*:NEW.Quantity - :New.unit_price*:NEW.Quantity*0.05;
      DBMS_OUTPUT.PUT_LINE(' le prix final après remise  est ' ||total_final '$');
      end if;

END;



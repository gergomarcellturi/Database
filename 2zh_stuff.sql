-- témánként->kiadóként->szerzõként hány db horror/scifi témájú könyv van.
select tema, kiado, vezeteknev, keresztnev
    from konyvtar.szerzo join konyvtar.konyvszerzo using (szerzo_azon)
    join konyvtar.konyv using (konyv_azon)
    where tema = 'sci-fi' or tema = 'horror'
    group by kiado;
    
select tema, kiado, szerzo_azon, vezeteknev, keresztnev, count(*)
    from KONYVTAR.konyv 
        natural join konyvtar.konyvszerzo
        natural join KONYVTAR.szerzo
    where tema in ('sci-fi', 'krimi', 'horro')
    group by tema, kiado, szerzo_azon, vezeteknev, keresztnev
    order by 1,2,3,4;
    
-- születési évenként hány könyvet nem hoztak még vissza az olvasók

select to_char(szuletesi_datum, 'yyyy') "Születési év", count(*) "Darabszám"
    from konyvtar.tag join KONYVTAR.kolcsonzes
        on (tag_azon = olvasojegyszam)
    where konyvtar.kolcsonzes.visszahozasi_datum is null
    group by to_char(szuletesi_datum,'yyyy')
    order by 1;
    
-- azon könyvek címei abc-ben növekvõ sorrendben, melyeket nem kölcsönöztek ki.


select cim from konyvtar.konyv
minus
select cim from konyvtar.konyv
    where konyv_azon in
        (select konyv_azon from konyvtar.konyvtari_konyv
            where leltari_szam in
                (select leltari_szam from konyvtar.kolcsonzes))
        order by 1;


select cim from konyvtar.konyv
    where konyv_azon not in
        (select konyv_azon from konyvtar.konyvtari_konyv
            where leltari_szam in
                (select leltari_szam from konyvtar.kolcsonzes))
    order by 1;
    
select distinct cim from konyvtar.konyv 
    join konyvtar.konyvtari_konyv 
        using(konyv_azon)
    left join konyvtar.kolcsonzes
        using(leltari_szam)
    where kolcsonzesi_datum is null
    order by 1;
    
    
    
    
-- Data Definition Language (DDL)

-- Create Table <táblanév> ( [<oszlopleírás> | <táblamegszorítás>], ... );

-- <oszlopleírás>: <oszlopnév> <típus> [<oszlopmegszorítás>]...

-- <megszorítás>: [CONSTRAINT <név>] <leírás>


-- hozzunk létre 'tulaj' nevá táblát az alábbi oszlopokkal: 'azon' (ötjegyû egész szám), 'nev' (max 30 karakteres string)
-- 'szuldat' (dátumtípus), 'szemelyszam' (pontosan 11 karakteres string)
-- a 'név' nem vehet fel null értéket
-- a 'szemelyszam' sem vehet fel null értéket
-- elsõdleges kulcs 'azon'
-- 'szemelyszam' másodlagos kulcs
    
-- <típus>: 
-- NUMBER | NUMBER(p) | NUMBER(p,r), 
-- CHAR(n): n karakterbõl álló karaktersorozat (string).Fix hosszúságú string.
-- VARCHAR2(n): maximum n hosszúságú string, jobb helyfoglalással
-- DATE: Dátum


create table tulaj
(
    azon number(5),
    nev varchar2(30) constraint tulaj_nn_nev not null,
    szul_dat date default sysdate,
    szemelyiszam char(11) constraint tulaj_nn_szsz not null,
    constraint tulaj_pk primary key(azon),
    constraint tulaj_un_szsz unique(szemelyiszam)
);

drop table tulaj;


-- tábla 'auto' néven: 'rendszam' (6 karakteres string), 'szin' (10 karakteres string), 'tulaj_azon'( 5 jegyû szám)
-- 'ar' mezõ(maximum 10 tizedesjegy, ebbõl 2 törtrész)
-- constraints:
-- elsõdleges kulcs -> 'rendszam'
-- külsõ kulcs -> 'tulaj_azon' (tulaj táblának 'azon' részére hivatkozik)
-- az 'ar' nem lehet 10 000 kisebb

create table auto
(
    rendszam char(6),
    szin varchar2(10),
    tulaj_azon number(5),
    ar number(8,2) constraint auto_ck_ar check(ar>=10000),
    constraint auto_pk2 primary key(rendszam),
    constraint auto_fk_tulaj foreign key(tulaj_azon) references tulaj
);

drop table auto;
-- create table <táblanév>
--  AS SELECT...;


-- olvasóink vezetkénevét, keresztnevét és hogy hágy kölcsönzésük volt. Azok is szerepeljenek,
-- akiknek még egy kölcsönzése sem volt.

create table kolcson as
    select vezeteknev, keresztnev, count(tag_azon) kolcsonzesek
        from konyvtar.tag left join konyvtar.kolcsonzes
            on olvasojegyszam = tag_azon
        group by olvasojegyszam, vezeteknev, keresztnev;

drop table kolcson;

-- ALTER TABLE <táblanév>

--  ADD (új oszlopmegszorítás megadása)
--  MODOFY (oszlopnév által módosítás)
--  RENAME TO <táblanév> (táblanév átnevezése)
--  RENAME COLOUMN <oszlopnév> TO <új_oszlopnév> (oszlopátnevezés)
--  RENAME CONSTRAINT <név> TO <új_név> (megszorítás átnevezése)
--  DROP CONSTRAINT <név> (megszorítás törlése)
--  DROP PRIMARY KEY (elsõdleges kulcs törlése)
--  RENAME <táblanév> TO <új_táblanév> (tábla átnevezése)

alter table kolcson
    add primary key (vezeteknev, keresztnev, kolcsonzesek);
    
alter table kolcson
    add tag_azon number;
    
alter table kolcson
    drop primary key;

alter table kolcson
    add constraint kolcson_pk primary key(tag_azon);

create sequence szekv;

update kolcson set tag_azon = SZEKV.nextval;

-- auto táblához vegyünk fel egy 20 karakteres string

alter table auto
    add tipus varchar2(20);
    
alter table auto
    rename column tipus to modell;
    
alter table auto
    rename to kocsi;
    
rename kocsi to auto;

alter table auto
    drop constraint auto_ck_ar;
    
alter table auto
    modify (rendszam varchar2(10), szin varchar2(5));

-- alter table xxx drop coloumn mezo; (oszlop törlése)


-- DML (data manipulation Language)
-- Select...
-- INSERT
-- DELETE
-- UPDATE
-- MERGE

-- INSERT INTO <táblanév>
-- [<oszlop>, ...]
-- VALUES (<kifejezés>, ...)

-- INSERT INTO <táblanév>
-- [(<oszlop>, ...)]
-- SELECT ...; (ha már egy sor nem megfelelõ, nem fog mûködni.)

truncate table tulaj; -- kitörli a tábla összes elemét. (kivétel ha van rajta megszorítás)
delete from auto;
delete from tulaj cascade; -- kitörli a tábla összes elemét.


insert into tulaj 
    values(2, 'Tóth Géza', to_date('1999.12.31', 'yyyy.mm.dd'), '19912311234');
    
    
insert into tulaj(nev, azon)
    values ('Kovacs Anna', 10);
    
insert into tulaj(azon,nev)
    values(10,' ');    
    
alter table tulaj drop constraint TULAJ_NN_SZSZ;

insert into tulaj
    select mod(konyv_azon,power(10,5)),
        substr(cim, 1, 50),
        kiadas_datuma,
        substr(isbn, 3)
        from konyvtar.konyv
        where tema like 's%';

-- DELETE FROM <táblanév>
-- [WHERE <feltétel>];


-- Töröljük ki azokat a tulajdonosokat, akiknek páratlan az azonosítója

delete from tulaj where mod(azon,2) = 1;

-- UPDATE <táblanév>
-- SET <oszlopnév> = <kifejezés> [,...]
-- [WHERE <feltétel>];

update tulaj
    set nev = 'Kovács Anna'
    where azon = 10;

-- 1. az elsején születésû emberek nagy betûre állítása, 2. +1 nap a dátumhoz

update tulaj
    set nev = upper(nev),
    szul_dat = szul_dat+1
    where extract(day from szul_dat) = 1;

-- UPDATE <táblanév>
-- SET (<oszlop1>, <oszlop2>, ...) = (SELECT ...)
-- [WHERE <feltétel>];

update kolcson
    set kolcsonzesek = null;
    
update kolcson
    set (kolcsonzesek,vezeteknev) = 
        (select count(tag_azon) kolcsonzesek, upper(vezeteknev)
            from KONYVTAR.tag t left join konyvtar.kolcsonzes
                on olvasojegyszam = tag_azon
            where t.vezeteknev = kolcson.vezeteknev and t.keresztnev = kolcson.keresztnev
            group by t.olvasojegyszam, t.vezeteknev);
            
            commit;
            
update kolcson
    set vezeteknev = initcap(vezeteknev);
    
rollback;
set autocommit on;
set autocommit off;

update kolcson 
    set vezeteknev = upper(vezeteknev);
            
            
/*
DCL (Data Control Language)

Tranzakció kezelés (nem lesz a dolgozatban)
    COMMIT; (véglegesítés)
    ROLLBACK; (visszavonás, visszagörgetés)
    SET AUTOCOMMIT ON; (minden végrehajtás után automatikusan jöjjön COMMIT)
    SAVEPOINT <mentési_pont>
    
Jogosultságkezelés
    GRANT (jogosultság adása)
    
    GRANT [<jogosultság> | ALL [PRIVILEGES]]
    [on <sémaobjektum>]
    TO [<felhasználónév>, ... | PUBLIC]
    [WITH GRANT OPTION];
    
    
    REVOKE (Jogosultság elvétele)
    
    REVOKE[<jogosultság> ,... | ALL [PRIVILEGES]]
        [on <sémeobjektum>]
    FROM[<felhasználónév>, ... | PUBLIC]
    
    
    <jogosultság>:
    - rendszerjog
    - objektumjog:
            - SELECT
            - INSERT ([OPC] <oszlopnév> ...)
            - DELETE
            - UPDATE ([OPC] <oszlopnév> ...)
            - REFERENCES ([OPC] <oszlopnév> ...)
    
    
          
*/

-- [OPC]: opcionális


grant insert, update(kolcsonzesek), on kolcson to u_joc0zo;

insert into dzsoni.kolcson values('V', 'K', 111,111);

update dzsoni.kolcson set kolcsonzesek = kolcsonzesek + 1;

revoke update on kolcson from u_joc0zo;

grant all on kolcson to u_joc0zo;

/*
    ALL és ANY
    
    <kifejezés> <operátor> [ALL(SELECT) | ANY(SELECT)]
    
    ALL:
    <kifejezés> <operátor>v1 AND
    <kifejezés> <operátor>v2 AND
    .
    .
    .
    <kifejezés> <operátor>vn
    
    ANY:
    <kifejezés> <operátor>v1 OR
    <kifejezés> <operátor>v2 OR
    .
    .
    .
    <kifejezés> <operátor>vn
    
    
    !SELECT egy oszlopos, akárhány soros!
    (SELECT) -> (v1, v2, ... vn)
    <operátor>: =, <>, <, >, <=, >=



*/















































































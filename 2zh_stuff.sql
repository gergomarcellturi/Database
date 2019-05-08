-- t�m�nk�nt->kiad�k�nt->szerz�k�nt h�ny db horror/scifi t�m�j� k�nyv van.
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
    
-- sz�let�si �venk�nt h�ny k�nyvet nem hoztak m�g vissza az olvas�k

select to_char(szuletesi_datum, 'yyyy') "Sz�let�si �v", count(*) "Darabsz�m"
    from konyvtar.tag join KONYVTAR.kolcsonzes
        on (tag_azon = olvasojegyszam)
    where konyvtar.kolcsonzes.visszahozasi_datum is null
    group by to_char(szuletesi_datum,'yyyy')
    order by 1;
    
-- azon k�nyvek c�mei abc-ben n�vekv� sorrendben, melyeket nem k�lcs�n�ztek ki.


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

-- Create Table <t�blan�v> ( [<oszlople�r�s> | <t�blamegszor�t�s>], ... );

-- <oszlople�r�s>: <oszlopn�v> <t�pus> [<oszlopmegszor�t�s>]...

-- <megszor�t�s>: [CONSTRAINT <n�v>] <le�r�s>


-- hozzunk l�tre 'tulaj' nev� t�bl�t az al�bbi oszlopokkal: 'azon' (�tjegy� eg�sz sz�m), 'nev' (max 30 karakteres string)
-- 'szuldat' (d�tumt�pus), 'szemelyszam' (pontosan 11 karakteres string)
-- a 'n�v' nem vehet fel null �rt�ket
-- a 'szemelyszam' sem vehet fel null �rt�ket
-- els�dleges kulcs 'azon'
-- 'szemelyszam' m�sodlagos kulcs
    
-- <t�pus>: 
-- NUMBER | NUMBER(p) | NUMBER(p,r), 
-- CHAR(n): n karakterb�l �ll� karaktersorozat (string).Fix hossz�s�g� string.
-- VARCHAR2(n): maximum n hossz�s�g� string, jobb helyfoglal�ssal
-- DATE: D�tum


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


-- t�bla 'auto' n�ven: 'rendszam' (6 karakteres string), 'szin' (10 karakteres string), 'tulaj_azon'( 5 jegy� sz�m)
-- 'ar' mez�(maximum 10 tizedesjegy, ebb�l 2 t�rtr�sz)
-- constraints:
-- els�dleges kulcs -> 'rendszam'
-- k�ls� kulcs -> 'tulaj_azon' (tulaj t�bl�nak 'azon' r�sz�re hivatkozik)
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
-- create table <t�blan�v>
--  AS SELECT...;


-- olvas�ink vezetk�nev�t, keresztnev�t �s hogy h�gy k�lcs�nz�s�k volt. Azok is szerepeljenek,
-- akiknek m�g egy k�lcs�nz�se sem volt.

create table kolcson as
    select vezeteknev, keresztnev, count(tag_azon) kolcsonzesek
        from konyvtar.tag left join konyvtar.kolcsonzes
            on olvasojegyszam = tag_azon
        group by olvasojegyszam, vezeteknev, keresztnev;

drop table kolcson;

-- ALTER TABLE <t�blan�v>

--  ADD (�j oszlopmegszor�t�s megad�sa)
--  MODOFY (oszlopn�v �ltal m�dos�t�s)
--  RENAME TO <t�blan�v> (t�blan�v �tnevez�se)
--  RENAME COLOUMN <oszlopn�v> TO <�j_oszlopn�v> (oszlop�tnevez�s)
--  RENAME CONSTRAINT <n�v> TO <�j_n�v> (megszor�t�s �tnevez�se)
--  DROP CONSTRAINT <n�v> (megszor�t�s t�rl�se)
--  DROP PRIMARY KEY (els�dleges kulcs t�rl�se)
--  RENAME <t�blan�v> TO <�j_t�blan�v> (t�bla �tnevez�se)

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

-- auto t�bl�hoz vegy�nk fel egy 20 karakteres string

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

-- alter table xxx drop coloumn mezo; (oszlop t�rl�se)


-- DML (data manipulation Language)
-- Select...
-- INSERT
-- DELETE
-- UPDATE
-- MERGE

-- INSERT INTO <t�blan�v>
-- [<oszlop>, ...]
-- VALUES (<kifejez�s>, ...)

-- INSERT INTO <t�blan�v>
-- [(<oszlop>, ...)]
-- SELECT ...; (ha m�r egy sor nem megfelel�, nem fog m�k�dni.)

truncate table tulaj; -- kit�rli a t�bla �sszes elem�t. (kiv�tel ha van rajta megszor�t�s)
delete from auto;
delete from tulaj cascade; -- kit�rli a t�bla �sszes elem�t.


insert into tulaj 
    values(2, 'T�th G�za', to_date('1999.12.31', 'yyyy.mm.dd'), '19912311234');
    
    
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

-- DELETE FROM <t�blan�v>
-- [WHERE <felt�tel>];


-- T�r�lj�k ki azokat a tulajdonosokat, akiknek p�ratlan az azonos�t�ja

delete from tulaj where mod(azon,2) = 1;

-- UPDATE <t�blan�v>
-- SET <oszlopn�v> = <kifejez�s> [,...]
-- [WHERE <felt�tel>];

update tulaj
    set nev = 'Kov�cs Anna'
    where azon = 10;

-- 1. az elsej�n sz�let�s� emberek nagy bet�re �ll�t�sa, 2. +1 nap a d�tumhoz

update tulaj
    set nev = upper(nev),
    szul_dat = szul_dat+1
    where extract(day from szul_dat) = 1;

-- UPDATE <t�blan�v>
-- SET (<oszlop1>, <oszlop2>, ...) = (SELECT ...)
-- [WHERE <felt�tel>];

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

Tranzakci� kezel�s (nem lesz a dolgozatban)
    COMMIT; (v�gleges�t�s)
    ROLLBACK; (visszavon�s, visszag�rget�s)
    SET AUTOCOMMIT ON; (minden v�grehajt�s ut�n automatikusan j�jj�n COMMIT)
    SAVEPOINT <ment�si_pont>
    
Jogosults�gkezel�s
    GRANT (jogosults�g ad�sa)
    
    GRANT [<jogosults�g> | ALL [PRIVILEGES]]
    [on <s�maobjektum>]
    TO [<felhaszn�l�n�v>, ... | PUBLIC]
    [WITH GRANT OPTION];
    
    
    REVOKE (Jogosults�g elv�tele)
    
    REVOKE[<jogosults�g> ,... | ALL [PRIVILEGES]]
        [on <s�meobjektum>]
    FROM[<felhaszn�l�n�v>, ... | PUBLIC]
    
    
    <jogosults�g>:
    - rendszerjog
    - objektumjog:
            - SELECT
            - INSERT ([OPC] <oszlopn�v> ...)
            - DELETE
            - UPDATE ([OPC] <oszlopn�v> ...)
            - REFERENCES ([OPC] <oszlopn�v> ...)
    
    
          
*/

-- [OPC]: opcion�lis


grant insert, update(kolcsonzesek), on kolcson to u_joc0zo;

insert into dzsoni.kolcson values('V', 'K', 111,111);

update dzsoni.kolcson set kolcsonzesek = kolcsonzesek + 1;

revoke update on kolcson from u_joc0zo;

grant all on kolcson to u_joc0zo;

/*
    ALL �s ANY
    
    <kifejez�s> <oper�tor> [ALL(SELECT) | ANY(SELECT)]
    
    ALL:
    <kifejez�s> <oper�tor>v1 AND
    <kifejez�s> <oper�tor>v2 AND
    .
    .
    .
    <kifejez�s> <oper�tor>vn
    
    ANY:
    <kifejez�s> <oper�tor>v1 OR
    <kifejez�s> <oper�tor>v2 OR
    .
    .
    .
    <kifejez�s> <oper�tor>vn
    
    
    !SELECT egy oszlopos, ak�rh�ny soros!
    (SELECT) -> (v1, v2, ... vn)
    <oper�tor>: =, <>, <, >, <=, >=



*/















































































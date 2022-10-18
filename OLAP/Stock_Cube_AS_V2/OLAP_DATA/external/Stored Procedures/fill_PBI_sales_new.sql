

CREATE PROCEDURE [external].[fill_PBI_sales_new]
AS
BEGIN
TRUNCATE TABLE [external].[PBI_sales];
WITH vzv
     AS (
     SELECT pn.link,
            amount=-SUM(dc.amount)
     FROM uchet.dbo.doc_ref
     AS pn(NOLOCK)
     LEFT JOIN
     uchet.dbo.document
     AS dc(NOLOCK)
     ON pn.code=dc.upcode
     WHERE pn.type_doc='П/Н+'
           AND dc.oper=513
           AND pn.link!=0
     GROUP BY pn.link),
     payments
     AS (
     SELECT dr.link,
            pay_type=CASE MIN(dc.oper)
                       WHEN 545
                       THEN 'Безнал'
                       WHEN 518
                       THEN 'Карта'
                       WHEN 80
                       THEN 'Нал'
                       WHEN 552
                       THEN 'НП'
                       ELSE ''
                     END
     FROM uchet.dbo.doc_ref
     AS dr(NOLOCK)
     LEFT JOIN
     uchet.dbo.document
     AS dc(NOLOCK)
     ON dr.code=dc.upcode
-- Тут тоже убрал джойн
     WHERE dc.oper IN
(518,
 80,
 545,
 552)
           AND dr.link!=0
     GROUP BY dr.link),
     orders
     AS (
--Продажи
     SELECT id=s.code,
            nn=s.nn,
            date_rez=CASE
                       WHEN drp.rez_date='19000101'
                       THEN s.date
                       ELSE ISNULL(drp.rez_date, s.date)
                     END,
            utm=REPLACE(ISNULL(dro.UtmSource, ''), ' ', '')+' '+REPLACE(ISNULL(dro.UtmMedium, ''), ' ', ''),
            region=ISNULL(reg.name, ''),
            region_up1=ISNULL(reg.name, ''),
            delivery_fact=ISNULL(drd.fact_amount, 0),
            TK=ISNULL(drd.ai_trcompany, ''),
            ai_trID=ISNULL(drd.ai_trID, ''),
            volOur=ISNULL(dro.volOur, 0),
            wtOur=ISNULL(dro.wtOur, 0),
            volTK=ISNULL(dro.volTK, 0),
            wtTK=ISNULL(dro.wtTK, 0),
            client=ISNULL(c.name, ''),
            client_up1=ISNULL(c_up1.name, ''),
            client_type=CASE ISNULL(c.nick, '')
                          WHEN 'ОПТ' THEN 'ОПТ'
                          WHEN 'ПСР' THEN 'ПСР'
                          WHEN 'ДИЛЕР' THEN 'ДИЛЕР'
                          ELSE 'РОЗ'
                        END,
            source=CASE
                     WHEN c_up1.code IN(276, 311, 312, 309, 310, 315)
                     THEN 'Интернет'
                     WHEN c_up1.code IN(3, 301, 331, 367, 332, 390, 193)
                     THEN 'Магазины'
                     WHEN c_up1.code IN(334, 345, 346, 347, 500)
                     THEN 'Опт'
                     WHEN c_up1.code IN(370)
                     THEN 'Клиенты СПБ'
                     WHEN c_up1.code IN(371)
                     THEN 'Краснодар'
                     ELSE 'Неопределен'
                   END
     FROM uchet.dbo.doc_ref
     AS s(NOLOCK)
     LEFT JOIN
     uchet.dbo.DrfDelivery
     AS drd(NOLOCK)
     ON s.code=drd.upcode
         LEFT JOIN
         uchet.dbo.DrfOrder
     AS dro(NOLOCK)
         ON dro.upcode=s.code
             LEFT JOIN
             uchet.dbo.DrfParam
     AS drp(NOLOCK)
             ON drp.upcode=s.code
                 LEFT JOIN
                 uchet.dbo.region
     AS reg(NOLOCK)
                 ON LTRIM(STR(reg.code))=LTRIM(RTRIM(drd.ai_city))
                    OR ISNULL(drd.ai_city, '')=''
                       AND reg.code=1136
--LEFT JOIN uchet.dbo.region reg_up1 (NOLOCK) ON reg_up1.code=reg.code

                     LEFT JOIN
                     uchet.dbo.company
     AS c(NOLOCK)
                     ON c.code=s.c_to
                         LEFT JOIN
                         uchet.dbo.company
     AS c_up1(NOLOCK)
                         ON c_up1.code=c.upcode
     WHERE s.type_doc IN
('СчМК',
 'ЛИД',
 'ЛИДА',
 'СЧА',
 'СМо1',
 'СМо2',
 'СМо3',
 'СМо4',
 'СМо5',
 'СМо6',
 'СМо7',
 'СМо8',
 'СМо9',
 'СМо')
           AND (s.code=s.link
                OR s.link=0)
           AND s.owner=23
           AND s.date>'20141231'
     UNION ALL
     SELECT id=0,
            nn='Нет',
            date_rez='19000101',
            utm='',
            region='',
            region_up1='',
            delivery_fact=0,
            TK='',
            ai_trID='',
            volOur=0,
            wtOur=0,
            volTK=0,
            wtTK=0,
            client='',
            client_up1='',
            client_type='',
            source=''),
     trans
     AS (
--Продажи
     SELECT [date]=MIN(rn.date),
            date_rez=ISNULL(ord.date_rez, MIN(rn.date)),
            id=0
            , --rn.code
            OrderId=ISNULL(ord.id, 0),
            nn='',
            nn_sch=ISNULL(ord.nn, ''),
            client=ISNULL(ord.client, ''),
            client_up1=ISNULL(ord.client_up1, ''),
            client_type=ISNULL(ord.client_type, ''),
            source=ISNULL(ord.source, ''),
            region=ISNULL(ord.region, ''),
            region_up1=ISNULL(region_up1, ''),
            TK=ISNULL(ord.TK, ''),
            pay_type=ISNULL(pay.pay_type, ''),
            utm=ISNULL(utm, ''),
            amount=SUM(CASE
                         WHEN dc.tovar!=6653
                         THEN dc.amount
                         ELSE 0
                       END),
            delivery=SUM(CASE
                           WHEN dc.tovar=6653
                           THEN dc.amount
                           ELSE 0
                         END),
            [return]=ISNULL(SUM(vzv.amount), 0),
            amountwithoutreturn=SUM(CASE
                                      WHEN dc.tovar!=6653
                                      THEN dc.amount
                                      ELSE 0
                                    END)-ISNULL(SUM(vzv.amount), 0),
            sebest_delivery=SUM(CASE
                                  WHEN dc.tovar=6653
                                  THEN ISNULL(dcp.am_cost, 0)
                                  ELSE 0
                                END),
            delivery_fact=ISNULL(MAX(ord.delivery_fact), 0),
            ai_trID=ISNULL(MAX(ord.ai_trID), ''),
            volOur=ISNULL(MAX(ord.volOur), 0),
            wtOur=ISNULL(MAX(ord.wtOur), 0),
            volTK=ISNULL(MAX(ord.volTK), 0),
            wtTK=ISNULL(MAX(ord.wtTK), 0)
     FROM uchet.dbo.doc_ref
     AS rn(NOLOCK)
     INNER JOIN
     uchet.dbo.document
     AS dc(NOLOCK)
     ON rn.code=dc.upcode
--INNER JOIN opers ON opers.oper=dc.oper --upcode
         LEFT JOIN
         uchet.dbo.docparam
     AS dcp(NOLOCK)
         ON dc.code=dcp.upcode
             LEFT JOIN
             vzv
             ON rn.link!=0
                AND vzv.link=rn.link
                 INNER JOIN
                 orders
     AS ord
                 ON ord.id=rn.link
                     LEFT JOIN
                     payments
     AS pay
                     ON ord.id=pay.link
     WHERE rn.type_doc!='П/Н+'
           AND rn.owner=23
           AND rn.date>'20141231'
           AND dc.quantity>0
-- избавился от cte opers 
           AND dc.oper IN
(
  SELECT upcode
  FROM uchet.dbo.oper
(NOLOCK)
  WHERE oper.acck IN
('021',
 '03')
  GROUP BY upcode,
           acck
)
     GROUP BY ISNULL(ord.id, 0),
              ord.nn,
              ord.region,
              ord.region_up1,
              date_rez,
              utm,
              ord.TK,
              client,
              client_type,
              client_up1,
              source,
              pay_type)
     INSERT INTO [OLAP_DATA].[external].[PBI_sales]
([Дата],
 [Дата резерва],
 [ID заказа],
 [ID счета],
 [Номер],
 [Номер счета],
 [Клиент],
 [Тип клиента],
 [Клиенты папка],
 [Способ оплаты],
 [Источник],
 [Город],
 [Область],
 utm,
 [Способ доставки],
 [Сумма заказа],
 [Доставка],
 [Доставка факт],
 [Себестоимость доставки],
 [Возвраты],
 [Сумма минус возвраты],
 [Объем ТК],
 [Вес ТК],
 [Объем],
 [Вес],
 [Трекинговый номер])
            SELECT [date],
                   date_rez,
                   id,
                   OrderId,
                   nn,
                   nn_sch,
                   client,
                   client_type,
                   client_up1,
                   pay_type,
                   source,
                   region,
                   region_up1,
                   utm,
                   TK,
                   amount,
                   delivery,
                   delivery_fact,
                   sebest_delivery,
                   [return],
                   amountwithoutreturn,
                   volTK,
                   wtTK,
                   volOur,
                   wtOur,
                   ai_trID
            FROM trans
            ORDER BY date DESC;
END;
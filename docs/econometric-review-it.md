# Revisione econometrica — 10 ottobre 2026

Questa nota descrive la versione precedente alle modifiche. Il primo intervento successivo ha corretto allineamento delle date, separazione IRF/FEVD, orizzonti ed etichette e aggiunto un seed e test di regressione. Le criticità di misura e identificazione restano aperte.

Un secondo intervento ha riorganizzato il repository, uniformato la crescita in log-differenze, introdotto controlli trimestrali deterministici e rigenerato figure e tabelle con bande bootstrap e confronto tra specificazioni. Il README e docs/data-dictionary.md descrivono il codice corrente; i percorsi e i valori discussi qui sotto restano riferiti alla revisione originaria. Il duplicato readme.md è stato rimosso dall'indice Git mantenendo README.md.

## Giudizio generale e perimetro

La domanda comparativa è valida: capire perché redditi, liquidità e prezzi si siano mossi diversamente negli USA e nell'area euro. Il progetto è una base utilizzabile per un'analisi esplorativa, ma le conclusioni causali del README originale superavano l'identificazione disponibile. Prima di aumentare la complessità bisogna rendere confrontabili i dati e distinguere innovazioni statistiche da shock economici.

Ho letto tutti gli script MATLAB, il README, intestazioni e formule rilevanti dei workbook e alcuni estratti delle fonti. Ho riprodotto separatamente le stime puntuali OLS/Cholesky/FEVD sui valori salvati negli Excel. Non ho eseguito MATLAB, il bootstrap o le restrizioni di segno, né ricostruito tutte le serie dalle fonti originali. Nessun codice, dataset o grafico è stato modificato.

## 1. Risultati verificati

### La FEVD pubblicata riguarda risposte cumulate

In main.m, righe 16–17, la quarta variabile viene cumulata modificando l'output. CholeskyIdentification conserva le risposte originali nel secondo output, cirfvar, ma main.m lo scarta. Alle righe 105 e 109 passa a fevd le risposte già cumulate.

Questo cambia l'oggetto della decomposizione, senza rendere intrinsecamente sbagliata la formula FEVD. Con inflazione in log-differenze, le risposte cumulate sono quelle del log del livello dei prezzi; con variazioni percentuali semplici, come negli USA, è un'approssimazione.

Verifica indipendente sui campioni effettivi, orizzonte di previsione di 20 trimestri, coefficienti delle risposte da 0 a 19:

| Campione e oggetto | OIL | GDP | UR | Prezzi | FISC | EGM | Tasso |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| EA: inflazione trimestrale | 18,68 | 9,92 | 4,38 | 61,67 | 2,28 | 1,57 | 1,50 |
| EA: inflazione cumulata | 29,73 | 9,63 | 7,44 | 43,12 | 0,41 | 3,89 | 5,77 |
| USA: inflazione trimestrale | 38,03 | 6,90 | 2,45 | 40,53 | 4,01 | 6,06 | 2,01 |
| USA: inflazione cumulata | 38,98 | 0,67 | 0,17 | 28,67 | 1,99 | 21,86 | 7,66 |

Quote percentuali arrotondate. Le righe cumulate riproducono i numeri del README precedente. Non sono risultati finali: restano problemi di dati, campione e identificazione e mancano intervalli.

**Intervento:** mantenere separatamente IRF originali e cumulate e denominare entrambe le FEVD. Nella figura IRF l'impatto è a 1; nella figura FEVD il conteggio parte da 0. Uniformare le convenzioni distinguendo indice della risposta e orizzonte dell'errore di previsione.

### Un trimestre USA in più

dataset_usa.xlsx!A130 è 1978Q4, correttamente usato come osservazione iniziale per differenziare FISC. Dopo la differenza si parte da 1979Q1. A318 è però 2025Q4, mentre il calendario manuale termina a 2025Q3. Il confronto USA contiene 95 osservazioni da 2002Q2 a 2025Q4, quello EA 94 fino a 2025Q3. I primi 71 trimestri sono correttamente 2002Q2–2019Q4: non emerge uno slittamento di tutto il campione.

Escludendo soltanto l'ultimo trimestre USA, EGM cumulata passa a 21,34% e non cumulata a 6,09%. La differenza non scompare, ma il confronto deve comunque avere estremi coerenti.

**Intervento:** leggere le date effettive e intersecare i trimestri, verificando frequenza, unicità, estremi e valori mancanti; evitare selezioni tramite numeri di riga.

### La proxy fiscale usa PIL nominale

La formula di dataset_eu.xlsx!J91 è `100*(LN(G91/E91)-LN(G90/E90))`: E è PIL nominale, F PIL reale. Anche il blocco descrittivo main.m:118–122 usa reddito/PIL nominale. Il rapporto USA è denominato DSPI_GDP. Il README precedente dichiarava PIL reale: la documentazione ora riflette il dato effettivo.

Dividere reddito nominale per PIL reale introdurrebbe anche il deflatore nel rapporto. Prima di cambiare la formula bisogna precisare il costrutto economico che si vuole misurare.

### Dati non ancora armonizzati

- HICP EA proviene da CP0000EZ19M086NEST, non destagionalizzata, mentre CPIAUCSL è la serie USA. Il baseline non include dummy stagionali. Questo può contaminare il confronto delle dinamiche trimestrali. [Metadati HICP](https://fred.stlouisfed.org/series/CP0000EZ19M086NEST).
- L'HICP è EA19; il CSV del PIL nominale indica EA20 e quello del reddito il codice I9. Documentare e armonizzare i perimetri.
- PIL ed EGM EA usano log-differenze, mentre le intestazioni USA indicano variazioni percentuali semplici: nel 2020 la differenza conta.
- M3 e M2, Euribor e federal funds rate, BFO e WTI non sono misure identiche. L'intestazione del petrolio EA contiene riferimenti sia a EUR sia a dollari/barile: chiarire la valuta effettiva dai metadati.
- L'HICP preparato coincide con la log-differenza del livello tranne il primo valore, 0,59 invece di circa 0,593024. È piccolo, ma segnala una preparazione parzialmente manuale.
- Manca una procedura riproducibile di aggregazione dei dati mensili: documentare media/fine periodo e ordine di aggregazione e trasformazione.

Serve un dizionario con fonte, serie, vintage, unità, frequenza, aggregazione, stagionalità, trasformazione e copertura geografica.

## 2. Critica dell'identificazione

### FISC non è automaticamente uno shock fiscale

Reddito disponibile/PIL risponde a trasferimenti e imposte, ma anche a salari, redditi patrimoniali, stabilizzatori automatici e cadute del denominatore. Chiamerei la variabile «crescita del reddito disponibile relativo al PIL», riservando «shock fiscale» a una strategia identificativa esplicita.

Occorre scegliere se interessano spesa pubblica, trasferimenti o imposte: non sono equivalenti. Strade possibili sono restrizioni istituzionali sulle risposte automatiche, shock narrativi o strumenti esterni, previa verifica di copertura e confrontabilità. [Blanchard e Perotti (2002)](https://www.nber.org/papers/w7269) è il riferimento di partenza, non una giustificazione automatica del rapporto attuale.

### EGM non identifica QE o monetizzazione

Moneta ampia significa anche credito, domanda di liquidità e composizione dei portafogli; non coincide con riserve o base monetaria. Il termine meno crescita del PIL incorpora meccanicamente la contrazione dell'attività: scomporre l'anomalia del 2020 nelle due componenti prima di chiamarla espansione monetaria.

Includere crescita del PIL ed EGM riutilizza il PIL con segno negativo. Non implica necessariamente collinearità perfetta, ma rende utile il confronto con un modello che usa direttamente crescita della moneta. Una trasformazione delle variabili non preserva automaticamente l'interpretazione ricorsiva degli shock. [BIS Bulletin 67](https://www.bis.org/publ/bisbull67.htm) motiva lo studio della moneta, senza identificare causalmente lo shock EGM.

### Petrolio, inerzia e mediazione

OIL per primo non distingue offerta petrolifera e domanda globale: impone una restrizione contemporanea. Anche la sua plausibilità negli USA va difesa. Per l'Europa 2021–2023, gas/energia e pressioni sulle catene di fornitura sono estensioni mirate da valutare. [Kilian (2009)](https://www.aeaweb.org/articles/pdf/doi/10.1257/aer.99.3.1053) chiarisce perché gli shock petroliferi non sono intercambiabili.

La quota dell'innovazione dei prezzi non è «inerzia»: la persistenza riguarda la propagazione dinamica, mentre la quota dipende anche da varianze, orizzonte e identificazione.

Una IRF fiscale visibile e una FEVD fiscale piccola non sono contraddittorie. La FEVD confronta le risposte a tutti gli shock su tutto l'orizzonte. Non dimostra che il fiscale «inneschi» lo shock monetario: gli shock strutturali del modello sono ortogonali e la risposta della moneta a uno shock fiscale è già parte della sua trasmissione. Una tesi di mediazione richiede un disegno aggiuntivo.

### FEVD non è decomposizione dell'inflazione osservata

Per spiegare il 2021–2023 serve una decomposizione storica di shock, condizioni iniziali e componenti deterministiche, dopo avere difeso l'identificazione. La FEVD ripartisce l'incertezza di previsione a un dato orizzonte. Nessuna delle due è indipendente dalle assunzioni identificative.

## 3. Inferenza e specificazione

Il VAR(2) ha 15 coefficienti per equazione, 105 nel sistema, oltre ai 28 elementi distinti della covarianza. EA completo ha 92 osservazioni effettive e pre-2020 ne ha 69: stimabile, ma sensibile a incertezza e trimestri estremi.

La replica puntuale trova radici massime di circa 0,96449 per EA completo, 0,87657 per USA confronto, 0,95645 per USA lungo e **0,999955 per EA pre-2020**. Il commento sul possibile modello USA esplosivo non descrive la replica attuale; la quasi radice unitaria EA pre-2020 è più preoccupante. Una radice stimata minore di uno non prova stazionarietà dei dati o adeguatezza della specificazione.

Le bande bootstrap sono calcolate ma non mostrate nella figura principale. Differenze tra curve non provano differenze statisticamente significative. Shock a una deviazione standard hanno inoltre ampiezze diverse tra paesi e periodi: mostrare anche normalizzazioni economiche comuni, dove sensate, distinguendo volatilità degli shock e trasmissione.

Il bootstrap ricampiona vettori di residui, preservando la dipendenza contemporanea ma non la sequenza di volatilità pandemica. Non controlla le repliche instabili e manca un seed. Non eliminerei le repliche problematiche silenziosamente: definire la procedura inferenziale, registrarne il trattamento e verificarne la sensibilità. Gli z-score rolling non risolvono il problema. [Lenza e Primiceri](https://www.ecb.europa.eu/pub/pdf/scpwps/ecb.wp2461~fe732949ee.en.pdf) è una lettura prioritaria sulla volatilità pandemica.

Altri interventi:

- Riattivare diagnostiche, controllare autocorrelazione residua e stabilità dei parametri. I t-test sui singoli lag non sostituiscono test congiunti dei blocchi e non provano causalità strutturale.
- Valutare pochi lag plausibili. VarOLSbestP, non chiamato dal baseline, confronta campioni diversi per lag e usa T grezzo nella penalizzazione: correggere la comparabilità prima di usarlo.
- Dichiarare la convenzione della covarianza: cov(u) divide per T−1, le diagnostiche per T−k. Una riscalatura comune non cambia le quote FEVD ma cambia la scala delle IRF.
- Evitare l'inversa esplicita per OLS. La funzione Cholesky assume una costante anche quando espone c=0: è un problema dell'interfaccia generale, non del baseline con c=1.
- Pre-pandemia e campione completo sono campioni sovrapposti, non automaticamente «regimi» identificati.

Gli z-score fiscali usano il livello del rapporto mentre il VAR usa la sua differenza logaritmica. Le analisi EGM descrittive eliminano anche l'ultimo trimestre disponibile e terminano a 2025Q2. Le bande rolling includono il trimestre corrente; il punteggio del picco usa la finestra precedente. Non interpretare differenze di deviazioni standard come quantità comparabili di liquidità ritirata.

## 4. Restrizioni di segno: prototipi da validare

Le routine non sono chiamate da main.m. Prima di integrarle:

1. La QR gaussiana di simult_puresign non normalizza Q con i segni della diagonale di R: controllare la costruzione delle rotazioni secondo la distribuzione desiderata.
2. Il confronto con sign interpreta 0 come zero esatto, senza una maschera di elementi liberi. Uno zero esatto non si ottiene generalmente per rigetto di estrazioni continue: richiede un algoritmo appropriato.
3. I segni sono controllati soltanto all'impatto, non su più trimestri.
4. independent_puresign estrae ogni shock separatamente, senza garantirne l'ortogonalità congiunta: non assemblarli come sistema completo per FEVD e decomposizioni storiche.
5. La mediana elemento per elemento non è necessariamente un modello ammissibile. Cumulare la mediana non equivale alla mediana delle cumulate: trasformare ogni estrazione prima dei quantili ed evitare input già cumulati due volte.
6. Combinare bootstrap e rotazioni accettate non produce automaticamente una distribuzione bayesiana o bande frequentiste validate. Esplicitare l'inferenza e il ruolo della probabilità di accettazione.

Leggere [Fry e Pagan (2011)](https://pubs.aeaweb.org/doi/abs/10.1257/jel.49.4.938) e [Arias, Rubio-Ramírez e Waggoner (2018; working paper)](https://www.federalreserve.gov/pubs/ifdp/2014/1100/ifdp1100.pdf). Non imporre un segno all'inflazione e poi presentarlo come scoperta empirica. Il price puzzle va investigato, non eliminato con restrizioni ad hoc.

## 5. Percorso consigliato

**Prima: baseline verificabile.** Armonizzare dati e date, separare inflazione e prezzi, pubblicare IRF con intervalli e FEVD a 1, 4, 8, 12 e 20 trimestri. Registrare esplicitamente le differenze di misura che restano.

**Poi: un obiettivo economico principale.** Suggerisco: «Quanto differisce la relazione dinamica tra reddito disponibile, moneta e prezzi nelle due aree, e quanto dipende dalle osservazioni pandemiche?». È coerente con i dati attuali. Confrontare componenti delle proxy, ordinamenti plausibili e trattamenti della volatilità.

**Quindi: estensione mirata.** Un BVAR parsimonioso con shrinkage e trattamento degli outlier è più giustificabile, con questo campione, di un TVP-VAR a sette variabili. Valutare sensibilità al prior: [Giannone, Lenza e Primiceri (2015; working paper)](https://www.ecb.europa.eu/pub/pdf/scpwps/ecbwp1494.pdf).

Se la domanda deve essere causale, ridefinire prima gli shock: trasferimenti/spesa/imposte; sorprese monetarie con strumenti plausibili; offerta/domanda energetica. Gli strumenti esterni richiedono rilevanza, esclusione e copertura sufficiente: non sono una soluzione automatica.

Per i risparmi in eccesso, aggiungere inizialmente una misura pertinente, per esempio tasso di risparmio o consumo reale, e verificare le implicazioni dell'ipotesi. Definire il controfattuale che rende i risparmi «in eccesso». Crescita dei consumi nominali non dimostra crescita reale o maggiore propensione marginale al consumo. Il riferimento comparativo più vicino è [Bernanke e Blanchard, analisi di 11 economie (2024)](https://www.brookings.edu/articles/an-analysis-of-pandemic-era-inflation-in-11-economies/).

TVP-VAR e machine learning vengono dopo. Forecasting richiede un obiettivo separato, finestre senza contaminazione futura, benchmark semplici e valutazione fuori campione. Una migliore previsione non convalida l'interpretazione causale.

## Modifiche effettuate

Il README ora descrive domanda, stato, specificazione, campioni effettivi, formule, esecuzione, struttura del progetto, limiti e letteratura. Le figure restano disponibili come preliminari. Monetizzazione, inerzia, fallimento della trasmissione e risparmi precauzionali non sono più presentati come risultati identificati.

La priorità del prossimo intervento sul codice è **date + stagionalità/trasformazioni + distinzione IRF/FEVD**, seguita da inferenza e identificazione. Queste correzioni non sono state implementate in questa revisione.

Nota sul repository: Git traccia sia README.md sia readme.md. Nel filesystem corrente i due nomi risolvono allo stesso file, quindi la modifica compare per entrambi. Unificare il nome in un intervento dedicato per evitare divergenze su filesystem sensibili alle maiuscole; non ho modificato l'indice Git.

// ==UserScript==
// @name         PrawkoNavi
// @namespace    http://tampermonkey.net/
// @version      0.3
// @description  Skrypt pozwala na sprawne poruszanie się za pomocą klawiszy, ćwicząc na stronie testynaprawojazdy.eu
// @author       Warvdoh Mróz, https://github.com/Warvdoh
// @match        https://www.testynaprawojazdy.eu/exam/exam/*
// @grant        none
// @run-at       document-end
// ==/UserScript==

(function() {
    'use strict';

    // Konfiguracja przypisania klawiszy: Łatwo zmień przypisania klawiszy tutaj(nie testowałem tego)
    const KEY_UP = 'ArrowUp';   // Strzałka w górę (Pokaż zdjęcie lub Pokaż video)
    const KEY_RIGHT = 'ArrowRight';  // Strzałka w prawo (Następne pytanie)
    const KEY_LEFT = 'ArrowLeft';    // Strzałka w lewo (Poprzednie pytanie)
    const KEY_DOWN = 'ArrowDown';    // Strzałka w dół (Sprawdź odpowiedź)

    // Funkcja obsługująca naciśnięcia klawiszy
    function handleKeyPress(event) {
        if (event.key === KEY_UP) {
            // Obsługuje Strzałkę w górę (kliknij na Pokaż zdjęcie lub Pokaż video)
            const imageButtons = document.querySelectorAll('img[ng-click="ctrl.showMedia()"]');
            if (imageButtons.length > 0) {
                imageButtons[0].click();
            }
        }
        else if (event.key === KEY_RIGHT) {
            // Obsługuje Strzałkę w prawo (kliknij na Następne pytanie)
            const nextQuestionButton = document.querySelector('img[ng-click="ctrl.nextQuestion()"]');
            if (nextQuestionButton) {
                nextQuestionButton.click();
            }
        }
        else if (event.key === KEY_LEFT) {
            // Obsługuje Strzałkę w lewo (kliknij na Poprzednie pytanie)
            const prevQuestionButton = document.querySelector('img[ng-click="ctrl.prevQuestion()"]');
            if (prevQuestionButton) {
                prevQuestionButton.click();
            }
        }
        else if (event.key === KEY_DOWN) {
            // Obsługuje Strzałkę w dół (kliknij na Sprawdź odpowiedź)
            const checkAnswerButton = document.querySelector('img[ng-click="ctrl.checkAnswer()"]');
            if (checkAnswerButton) {
                checkAnswerButton.click();
            }
        }
    }

    // Funkcja inicjalizująca nasłuchiwanie klawiszy, gdy elementy są dostępne
    function initializeKeyListeners() {
        // Sprawdzamy, czy wymagane przyciski są dostępne w DOM
        const imageButtons = document.querySelectorAll('img[ng-click="ctrl.showMedia()"]');
        const nextQuestionButton = document.querySelector('img[ng-click="ctrl.nextQuestion()"]');
        const prevQuestionButton = document.querySelector('img[ng-click="ctrl.prevQuestion()"]');
        const checkAnswerButton = document.querySelector('img[ng-click="ctrl.checkAnswer()"]');

        if (imageButtons.length > 0 && nextQuestionButton && prevQuestionButton && checkAnswerButton) {
            // Dodajemy nasłuchiwanie na naciśnięcie klawiszy
            window.addEventListener('keydown', handleKeyPress);
            console.log("Nasłuchiwanie klawiszy zostało zainicjowane");
        }
    }

    // Funkcja do zablokowania przewijania strony przy użyciu strzałek
    function disableArrowScroll(event) {
        // Zablokuj przewijanie strony przez strzałki
        if ([KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT].includes(event.key)) {
            event.preventDefault();
        }
    }

    // Czekamy na załadowanie strony, a następnie inicjujemy
    window.onload = function() {
        setTimeout(initializeKeyListeners, 1000); // Opóźnienie, aby umożliwić załadowanie treści
        // Dodajemy nasłuchiwanie na naciśnięcia strzałek, aby zablokować przewijanie
        window.addEventListener('keydown', disableArrowScroll, { passive: false });
    };
})();
//Jeśli uważasz, że przydał ci się skrypcik to postaw mi kawę :D o, tutaj --> https://buymeacoffee.com/warvdoh
//Ten skrypt obowiązuje licencja GNU General Public License v3.0 - więcej informacji na https://www.gnu.org/licenses/gpl-3.0.html

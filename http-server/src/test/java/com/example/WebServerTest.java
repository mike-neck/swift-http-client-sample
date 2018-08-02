/*
 * Copyright 2018 Shinya Mochida
 *
 * Licensed under the Apache License,Version2.0(the"License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,software
 * Distributed under the License is distributed on an"AS IS"BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.example;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.mock.web.reactive.function.server.MockServerRequest;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.web.reactive.server.WebTestClient;
import org.springframework.web.reactive.function.server.HandlerFunction;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerRequest;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import java.net.URI;
import java.time.*;
import java.time.format.DateTimeFormatter;

@SuppressWarnings("ALL")
class WebServerTest {

    @Configuration
    static class FixedClock {
        @Bean
        ClockFunction clockFunction() {
            return zoneId -> OffsetDateTime.of(
                    LocalDate.of(2018, Month.APRIL, 1), 
                    LocalTime.of(8, 59), 
                    ZoneOffset.ofHours(9));
        }
    }

    @Nested
    @ExtendWith(SpringExtension.class)
    @Import({Routing.class, MyHandler.class, FixedClock.class})
    class RoutingTest {

        final Routing routing;

        private RouterFunction<ServerResponse> routerFunction;

        @Autowired
        RoutingTest(Routing routing) {
            this.routing = routing;
        }

        @BeforeEach
        void routingFunction() {
            routerFunction = routing.routerFunction();
        }

        @Test
        void test() {
            final ServerRequest request = MockServerRequest.builder()
                    .method(HttpMethod.GET)
                    .uri(URI.create("/foo"))
                    .build();

            final Mono<HandlerFunction<ServerResponse>> handler = routerFunction.route(request);

            StepVerifier.create(handler.log())
                    .expectNextCount(1)
                    .verifyComplete();
        }

        @Test
        void notMatch() {
            final ServerRequest request = MockServerRequest.builder()
                    .method(HttpMethod.GET)
                    .uri(URI.create("/foo/baz"))
                    .build();

            final Mono<HandlerFunction<ServerResponse>> handler = routerFunction.route(request);

            StepVerifier.create(handler.log())
                    .verifyComplete();
        }
    }

    @ExtendWith(SpringExtension.class)
    @Import({Routing.class, MyHandler.class, FixedClock.class})
    @Nested
    class HandlingTest {

        final Routing routing;
        final ClockFunction clockFunction;

        @Autowired
        HandlingTest(Routing routing, ClockFunction clockFunction) {
            this.routing = routing;
            this.clockFunction = clockFunction;
        }

        private RouterFunction<ServerResponse> routerFunction;

        @BeforeEach
        void setupRoutingFunction() {
            routerFunction = routing.routerFunction();
        }

        @Test
        void test() {
            final OffsetDateTime time = clockFunction.now(ZoneId.of("UTC"));
            final String expectedTime = time.format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
            WebTestClient.bindToRouterFunction(routerFunction)
                    .build()
                    .get()
                    .uri("/foo")
                    .accept(MediaType.APPLICATION_JSON)
                    .exchange()
                    .expectStatus()
                    .isOk()
                    .expectHeader()
                    .contentType(MediaType.APPLICATION_JSON)
                    .expectBody()
                    .jsonPath("time").isEqualTo(expectedTime)
                    .jsonPath("message").isEqualTo("hello");
        }
    }
}

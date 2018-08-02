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

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerRequest;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Mono;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.Optional;

import static org.springframework.web.reactive.function.server.RequestPredicates.GET;
import static org.springframework.web.reactive.function.server.RouterFunctions.route;

@SpringBootApplication
public class WebServer {

    public static void main(String[] args) {
        SpringApplication.run(WebServer.class);
    }

    @Bean
    ClockFunction clockFunction() {
        return zoneId -> OffsetDateTime.now(Clock.system(zoneId));
    }
}

@Configuration
class Routing {

    private final MyHandler myHandler;

    Routing(MyHandler myHandler) {
        this.myHandler = myHandler;
    }

    @Bean
    RouterFunction<ServerResponse> routerFunction() {
        return route(
                GET("/{foo:[a-zA-Z0-9]+}"),
                myHandler::handle);
    }
}

@Component
class MyHandler {

    private static final Logger logger = LoggerFactory.getLogger(MyHandler.class);

    private static final DateTimeFormatter ISO_OFFSET_DATE_TIME = DateTimeFormatter.ISO_OFFSET_DATE_TIME;

    private final ClockFunction clockFunction;

    MyHandler(ClockFunction clockFunction) {
        this.clockFunction = clockFunction;
    }

    private static Optional<ZoneId> toZoneId(final String zoneId) {
        try {
            return Optional.ofNullable(ZoneId.of(zoneId));
        } catch (DateTimeException e) {
            return Optional.empty();
        }
    }

    Mono<ServerResponse> handle(final ServerRequest request) {
        logger.info("request: {}/ query: {}", request.path(), request.queryParams());
        final ZoneId zoneId = request.queryParam("time_zone")
                .flatMap(MyHandler::toZoneId)
                .orElseGet(() -> ZoneId.of("UTC"));
        final OffsetDateTime now = clockFunction.now(zoneId);
        final Map<String, String> map = Map.of("time", now.format(ISO_OFFSET_DATE_TIME), "message", "hello");
        return ServerResponse.ok().contentType(MediaType.APPLICATION_JSON)
                .body(BodyInserters.fromObject(map))
                .delayElement(Duration.ofMillis(300L));
    }
}

interface ClockFunction {
    OffsetDateTime now(final ZoneId zoneId);
}

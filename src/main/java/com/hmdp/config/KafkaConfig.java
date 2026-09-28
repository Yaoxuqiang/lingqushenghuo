package com.hmdp.config;

import com.fasterxml.jackson.databind.JsonDeserializer;
import com.fasterxml.jackson.databind.deser.std.StringDeserializer;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.listener.ContainerProperties;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.util.backoff.BackOff;
import org.springframework.util.backoff.FixedBackOff;

import java.net.SocketTimeoutException;
import java.util.HashMap;
import java.util.Map;

/**
 * 【秒杀链路消息队列使用】-1
 *      1. Ack模式: AckMode.RECORD：after-processing（处理后）模式，消费者会为其消费的每条信息发送 Ack 消息。
 *      2. 消费者重试策略, 当所有重试尝试都用尽时执行的逻辑: 告警，人工排查介入
 *      3. 可重试异常和不可重试异常
 */
@Slf4j
@Configuration
public class KafkaConfig {
    /**
     * 两次重试之间的等待时间（毫秒）。
     */
    @Value(value = "${kafka.backoff.interval:1000}")
    private Long interval;
    /**
     * 在放弃之前重新尝试操作的最大次数。
     */
    @Value(value = "${kafka.backoff.max_failure:3}")
    private Long maxAttempts;

    /*@Bean
    public ConcurrentKafkaListenerContainerFactory<String, Object> seckillVoucherOrderKafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, Object> factory = new ConcurrentKafkaListenerContainerFactory<>();
        // 设置消费异常处理策略
        factory.setCommonErrorHandler(errorHandler());
        // 如果存在重试策略，请将确认模式（ack mode）设置为 AckMode.RECORD，以确保在处理过程中发生错误时，消费者将重新投递消息
        factory.getContainerProperties().setAckMode(ContainerProperties.AckMode.RECORD);
        factory.afterPropertiesSet();
        factory.setConsumerFactory(consumerFactory());
        return factory;
    }

    @Bean
    public DefaultErrorHandler errorHandler() {
        BackOff fixedBackOff = new FixedBackOff(interval, maxAttempts);
        DefaultErrorHandler errorHandler = new DefaultErrorHandler((consumerRecord, exception) -> {
            // 当所有重试尝试都用尽时执行的逻辑
            // 告警，人工排查介入
            log.error("消费异常: topic={}, offset={}, 原因={}", consumerRecord.topic(), consumerRecord.offset(), exception.getMessage());
            // 模拟通讯软件通知或者电话通知告警

        }, fixedBackOff);
        // 我们可以指定哪些异常可重试，哪些不可重试
        errorHandler.addRetryableExceptions(SocketTimeoutException.class);
        errorHandler.addNotRetryableExceptions(NullPointerException.class);
        return errorHandler;
    }

    @Bean
    public ConsumerFactory<String, Object> consumerFactory() {
        Map<String, Object> props = new HashMap<>();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        props.put(ConsumerConfig.GROUP_ID_CONFIG, "your-group-id");
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, JsonDeserializer.class);
        return new DefaultKafkaConsumerFactory<>(props);
    }*/

}